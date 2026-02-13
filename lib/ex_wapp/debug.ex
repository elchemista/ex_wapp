defmodule ExWapp.Debug do
  @moduledoc """
  Debug module that mimics Go's wsdebug to test WebSocket handshake.

  Usage:
      iex -S mix
      iex> ExWapp.Debug.test_handshake()
      iex> ExWapp.Debug.test_full_handshake()
  """

  require Logger

  @url "wss://web.whatsapp.com/ws/chat"
  @origin "https://web.whatsapp.com"
  # WA\x06\x03
  @wa_header <<0x57, 0x41, 0x06, 0x03>>
  @noise_pattern "Noise_XX_25519_AESGCM_SHA256\x00\x00\x00\x00"

  alias WAWebProtobufsWa6.HandshakeMessage
  alias WAWebProtobufsWa6.HandshakeMessage.ClientHello
  alias ExWapp.Noise.Handshake

  def test_full_handshake do
    Logger.info("=== Full Handshake Test ===")

    # Generate key pairs
    # ephemeral
    e_kp = ExWapp.Signal.Keys.generate_key_pair()
    # static (for new device)
    s_kp = ExWapp.Signal.Keys.generate_key_pair()

    Logger.info("Ephemeral public: #{Base.encode16(e_kp.public, case: :lower)}")
    Logger.info("Static public: #{Base.encode16(s_kp.public, case: :lower)}")

    # Initialize noise handshake
    noise = Handshake.new(@noise_pattern, @wa_header)
    noise = Handshake.authenticate(noise, e_kp.public)

    # Build client hello
    client_hello = build_client_hello(e_kp.public)
    frame = build_frame(@wa_header, client_hello)

    Logger.info("Client hello frame: #{byte_size(frame)} bytes")

    headers = [{"Origin", @origin}]

    case WebSockex.start_link(
           @url,
           __MODULE__.FullClient,
           %{
             parent: self(),
             e_kp: e_kp,
             s_kp: s_kp,
             noise: noise,
             frame: frame
           },
           extra_headers: headers
         ) do
      {:ok, pid} ->
        Logger.info("WebSocket connected")

        receive do
          {:result, result} -> result
        after
          30_000 ->
            Logger.error("Timeout")
            WebSockex.cast(pid, :stop)
            {:error, :timeout}
        end

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defmodule FullClient do
    use WebSockex
    require Logger

    def handle_connect(_conn, state) do
      Logger.info("Connected, will send client hello...")
      send(self(), :send_client_hello)
      {:ok, Map.put(state, :phase, :waiting_server_hello)}
    end

    def handle_info(:send_client_hello, state) do
      Logger.info("Sending client hello frame...")
      {:reply, {:binary, state.frame}, state}
    end

    def handle_frame({:binary, data}, %{phase: :waiting_server_hello} = state) do
      Logger.info("Received server hello: #{byte_size(data)} bytes")

      # Parse WA frame
      <<_len::24, payload::binary>> = data

      case WAWebProtobufsWa6.HandshakeMessage.decode(payload) do
        {:ok, %{serverHello: %{} = server_hello}} ->
          Logger.info("Server hello decoded successfully")
          process_server_hello(state, server_hello)

        {:ok, other} ->
          Logger.error("Unexpected message: #{inspect(other)}")
          send(state.parent, {:result, {:error, :unexpected_message}})
          {:close, state}

        {:error, reason} ->
          Logger.error("Failed to decode: #{inspect(reason)}")
          send(state.parent, {:result, {:error, reason}})
          {:close, state}
      end
    end

    def handle_frame({:binary, data}, %{phase: :waiting_response} = state) do
      Logger.info("Received post-handshake response: #{byte_size(data)} bytes")
      Logger.info("Response hex: #{Base.encode16(data, case: :lower) |> String.slice(0, 200)}...")

      # Try to decrypt with transport keys
      case decrypt_response(state, data) do
        {:ok, plaintext} ->
          Logger.info("Decrypted response: #{byte_size(plaintext)} bytes")

          Logger.info(
            "Plaintext hex: #{Base.encode16(plaintext, case: :lower) |> String.slice(0, 200)}..."
          )

          send(state.parent, {:result, {:ok, plaintext}})

        {:error, reason} ->
          Logger.error("Failed to decrypt: #{inspect(reason)}")
          send(state.parent, {:result, {:error, {:decrypt_failed, reason}}})
      end

      {:close, state}
    end

    def handle_frame(frame, state) do
      Logger.warning("Unexpected frame: #{inspect(frame)}")
      {:ok, state}
    end

    def handle_disconnect(reason, state) do
      Logger.info("Disconnected: #{inspect(reason)}")
      send(state.parent, {:result, {:error, {:disconnected, reason}}})
      {:ok, state}
    end

    def handle_cast(:stop, state) do
      {:close, state}
    end

    defp process_server_hello(state, server_hello) do
      re = server_hello.ephemeral
      rs_ct = server_hello.static
      cert_ct = server_hello.payload

      Logger.info("Server ephemeral: #{Base.encode16(re, case: :lower)}")

      noise = state.noise
      e_kp = state.e_kp
      s_kp = state.s_kp

      # 1. Authenticate server ephemeral
      noise = ExWapp.Noise.Handshake.authenticate(noise, re)

      # 2. Mix DH(e, re)
      with {:ok, noise} <- ExWapp.Noise.Handshake.mix_shared_secret(noise, e_kp.private, re),
           # 3. Decrypt server static
           {:ok, noise, rs} <- ExWapp.Noise.Handshake.decrypt(noise, rs_ct),
           # 4. Mix DH(e, rs)
           {:ok, noise} <- ExWapp.Noise.Handshake.mix_shared_secret(noise, e_kp.private, rs),
           # 5. Decrypt certificate
           {:ok, noise, _cert} <- ExWapp.Noise.Handshake.decrypt(noise, cert_ct),
           # 6. Encrypt our static public
           {noise, s_pub_ct} <- ExWapp.Noise.Handshake.encrypt(noise, s_kp.public),
           # 7. Mix DH(s, re)
           {:ok, noise} <- ExWapp.Noise.Handshake.mix_shared_secret(noise, s_kp.private, re) do
        Logger.info("Decrypted server static: #{Base.encode16(rs, case: :lower)}")
        Logger.info("Encrypted our static: #{byte_size(s_pub_ct)} bytes")

        # Build a real ClientPayload like Go does
        {:ok, client_payload} = build_real_client_payload()
        Logger.info("ClientPayload size: #{byte_size(client_payload)} bytes")

        {noise, payload_ct} = ExWapp.Noise.Handshake.encrypt(noise, client_payload)

        # Build client finish
        client_finish = build_client_finish(s_pub_ct, payload_ct)
        # No header for subsequent frames
        frame = build_frame(<<>>, client_finish)

        Logger.info("Sending client finish: #{byte_size(frame)} bytes")

        # Derive transport keys
        {write_key, read_key} = ExWapp.Noise.Handshake.derive_transport_keys(noise)
        Logger.info("Transport keys derived")

        new_state =
          state
          |> Map.put(:phase, :waiting_response)
          |> Map.put(:write_key, write_key)
          |> Map.put(:read_key, read_key)
          |> Map.put(:rx_counter, 0)

        {:reply, {:binary, frame}, new_state}
      else
        {:error, reason} ->
          Logger.error("Handshake processing failed: #{inspect(reason)}")
          send(state.parent, {:result, {:error, reason}})
          {:close, state}
      end
    end

    defp build_client_finish(static_ct, payload_ct) do
      msg = %WAWebProtobufsWa6.HandshakeMessage{
        clientFinish: %WAWebProtobufsWa6.HandshakeMessage.ClientFinish{
          static: static_ct,
          payload: payload_ct
        }
      }

      WAWebProtobufsWa6.HandshakeMessage.encode!(msg) |> IO.iodata_to_binary()
    end

    defp build_frame(header, payload) do
      len = byte_size(payload)
      <<header::binary, len::unsigned-big-size(24), payload::binary>>
    end

    defp decrypt_response(state, data) do
      # Skip WA frame length prefix
      <<_len::24, ciphertext::binary>> = data

      key = state.read_key
      counter = state.rx_counter

      # Generate IV
      iv = <<0::64, counter::32>>

      # AES-GCM decrypt
      tag_len = 16

      if byte_size(ciphertext) < tag_len do
        {:error, :too_short}
      else
        body_len = byte_size(ciphertext) - tag_len
        <<body::binary-size(body_len), tag::binary-size(tag_len)>> = ciphertext

        case :crypto.crypto_one_time_aead(:aes_256_gcm, key, iv, body, <<>>, tag, false) do
          plaintext when is_binary(plaintext) -> {:ok, plaintext}
          :error -> {:error, :decrypt_failed}
        end
      end
    end

    defp build_real_client_payload do
      alias WAWebProtobufsWa6.ClientPayload
      alias WAWebProtobufsWa6.ClientPayload.UserAgent
      alias WAWebProtobufsWa6.ClientPayload.UserAgent.AppVersion
      alias WAWebProtobufsWa6.ClientPayload.WebInfo
      alias WAWebProtobufsWa6.ClientPayload.DevicePairingRegistrationData

      # Generate signal keys
      identity = ExWapp.Signal.Keys.generate_key_pair()
      signed_prekey = ExWapp.Signal.Keys.generate_signed_prekey(identity, 1)
      reg_id = :rand.uniform(65535)

      # Build device props (Firefox/Linux identity)
      device_props = <<
        0x0A,
        0x07,
        "Firefox"::binary,
        0x12,
        0x06,
        0x08,
        0x00,
        0x10,
        0x01,
        0x18,
        0x00,
        0x18,
        0x02,
        0x20,
        0x00,
        0x2A,
        0x17,
        0x18,
        0x80,
        0x50,
        0x20,
        0x01,
        0x30,
        0x00,
        0x38,
        0x01,
        0x40,
        0x01,
        0x48,
        0x01,
        0x50,
        0x01,
        0x58,
        0x01,
        0x60,
        0x01,
        0x70,
        0x01,
        0x78,
        0x00
      >>

      build_hash = :crypto.hash(:md5, "2.3000.1029948479")
      e_skey_id = <<1::big-32>> |> binary_part(1, 3)

      payload = %ClientPayload{
        passive: false,
        pull: false,
        userAgent: %UserAgent{
          platform: :WEB,
          appVersion: %AppVersion{primary: 2, secondary: 3000, tertiary: 1_029_948_479},
          mcc: "000",
          mnc: "000",
          osVersion: "0.1",
          manufacturer: "",
          device: "Desktop",
          osBuildNumber: "0.1",
          releaseChannel: :RELEASE,
          localeLanguageIso6391: "en",
          localeCountryIso31661Alpha2: "US"
        },
        webInfo: %WebInfo{
          webSubPlatform: :WEB_BROWSER
        },
        connectType: :WIFI_UNKNOWN,
        connectReason: :USER_ACTIVATED,
        devicePairingData: %DevicePairingRegistrationData{
          eRegid: <<reg_id::big-32>>,
          eKeytype: <<5>>,
          eIdent: identity.public,
          eSkeyID: e_skey_id,
          eSkeyVal: signed_prekey.public,
          eSkeySig: signed_prekey.signature,
          buildHash: build_hash,
          deviceProps: device_props
        }
      }

      {:ok, encoded} = ClientPayload.encode(payload)
      {:ok, IO.iodata_to_binary(encoded)}
    end
  end

  def test_handshake do
    Logger.info("=== ExWapp Debug Handshake Test ===")
    Logger.info("URL: #{@url}")
    Logger.info("Origin: #{@origin}")
    Logger.info("WA Header hex: #{Base.encode16(@wa_header, case: :lower)}")

    # Generate ephemeral key pair
    e_kp = ExWapp.Signal.Keys.generate_key_pair()
    Logger.info("Ephemeral public key (32 bytes): #{Base.encode16(e_kp.public, case: :lower)}")

    # Build client hello protobuf
    client_hello_msg = %HandshakeMessage{
      clientHello: %ClientHello{
        ephemeral: e_kp.public
      }
    }

    client_hello = HandshakeMessage.encode!(client_hello_msg) |> IO.iodata_to_binary()

    Logger.info(
      "ClientHello protobuf (#{byte_size(client_hello)} bytes): #{Base.encode16(client_hello, case: :lower)}"
    )

    # Build frame: header + 3-byte length + payload
    frame = build_frame(@wa_header, client_hello)
    Logger.info("Full frame (#{byte_size(frame)} bytes): #{Base.encode16(frame, case: :lower)}")

    # Connect with minimal headers (only Origin, like Go)
    headers = [{"Origin", @origin}]
    Logger.info("HTTP headers: #{inspect(headers)}")

    case WebSockex.start_link(@url, __MODULE__.DebugClient, %{parent: self()},
           extra_headers: headers
         ) do
      {:ok, pid} ->
        Logger.info("WebSocket connected, sending frame...")

        # Send the frame
        WebSockex.send_frame(pid, {:binary, frame})
        Logger.info("Frame sent, waiting for response...")

        # Wait for response
        receive do
          {:ws_frame, data} ->
            Logger.info(
              "Received response (#{byte_size(data)} bytes): #{Base.encode16(data, case: :lower) |> String.slice(0, 200)}..."
            )

            parse_server_response(data)

          {:ws_connected} ->
            Logger.info("WebSocket connected callback received")
            # Wait more for actual data
            receive do
              {:ws_frame, data} ->
                Logger.info("Received response (#{byte_size(data)} bytes)")
                parse_server_response(data)
            after
              10_000 ->
                Logger.error("Timeout waiting for server response after connect")
                WebSockex.cast(pid, :stop)
                {:error, :timeout}
            end

          {:ws_error, reason} ->
            Logger.error("WebSocket error: #{inspect(reason)}")
            {:error, reason}
        after
          15_000 ->
            Logger.error("Timeout waiting for any response (15s)")
            WebSockex.cast(pid, :stop)
            {:error, :timeout}
        end

      {:error, reason} ->
        Logger.error("Failed to connect: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_frame(header, payload) do
    len = byte_size(payload)
    <<header::binary, len::unsigned-big-size(24), payload::binary>>
  end

  defp build_client_hello(ephemeral_public) do
    msg = %HandshakeMessage{
      clientHello: %ClientHello{
        ephemeral: ephemeral_public
      }
    }

    HandshakeMessage.encode!(msg) |> IO.iodata_to_binary()
  end

  defp parse_server_response(data) when byte_size(data) < 3 do
    Logger.error("Response too short: #{byte_size(data)} bytes")
    {:error, :too_short}
  end

  defp parse_server_response(data) do
    <<len::unsigned-big-size(24), rest::binary>> = data
    Logger.info("WA frame length prefix: #{len}, remaining: #{byte_size(rest)} bytes")

    if byte_size(rest) < len do
      Logger.warning("Truncated frame: expected #{len}, got #{byte_size(rest)}")
      {:error, :truncated}
    else
      payload = binary_part(rest, 0, len)

      Logger.info(
        "Server payload (#{byte_size(payload)} bytes): #{Base.encode16(payload, case: :lower) |> String.slice(0, 200)}..."
      )

      case HandshakeMessage.decode(payload) do
        {:ok, %HandshakeMessage{serverHello: nil}} ->
          Logger.error("No serverHello in response")
          {:error, :no_server_hello}

        {:ok, %HandshakeMessage{serverHello: server_hello}} ->
          Logger.info("✅ Got ServerHello!")

          Logger.info(
            "  Ephemeral: #{Base.encode16(server_hello.ephemeral || <<>>, case: :lower)}"
          )

          Logger.info("  Static (encrypted): #{byte_size(server_hello.static || <<>>)} bytes")
          Logger.info("  Payload (encrypted): #{byte_size(server_hello.payload || <<>>)} bytes")
          {:ok, server_hello}

        {:error, reason} ->
          Logger.error("Failed to decode ServerHello: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  # Simple WebSockex client for debugging
  defmodule DebugClient do
    use WebSockex

    def handle_connect(_conn, state) do
      send(state.parent, {:ws_connected})
      {:ok, state}
    end

    def handle_frame({:binary, data}, state) do
      send(state.parent, {:ws_frame, data})
      {:ok, state}
    end

    def handle_frame(_frame, state) do
      {:ok, state}
    end

    def handle_disconnect(reason, state) do
      send(state.parent, {:ws_error, {:disconnected, reason}})
      {:ok, state}
    end

    def handle_cast(:stop, state) do
      {:close, state}
    end
  end
end
