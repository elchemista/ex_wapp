defmodule ExWapp.Example do
  @moduledoc """
  Tiny helper to try the full pairing flow from an `iex` prompt.

  Usage (from the project root):

      iex -S mix
      iex> ExWapp.Example.run()

  The function will:
    * start a session with persistent storage
    * kick off the websocket+Noise handshake
    * save QR code to /tmp/whatsapp_qr.svg
    * halt once the device scan succeeds or an error occurs

  ## Signal Implementation

  The project supports two Signal protocol implementations:
  - `:native` - Rust NIF implementation (default, recommended)
  - `:elixir` - Pure Elixir implementation (fallback)

  To switch implementations:

      # Check current implementation
      iex> ExWapp.Example.signal_info()

      # Switch to Elixir implementation
      iex> ExWapp.Example.use_elixir_signal()

      # Switch back to Native (Rust)
      iex> ExWapp.Example.use_native_signal()
  """

  @store_path "/tmp/ex_wapp/bot_session.etf"
  @store_dir "/tmp/ex_wapp"
  @qr_path "/tmp/whatsapp_qr.svg"

  @doc """
  Clears the stored session data. Use this when you get 401 errors or want to re-pair.
  """
  def clear_session do
    IO.puts("🗑️  Clearing session data...")

    case File.rm_rf(@store_dir) do
      {:ok, _} ->
        IO.puts("✅ Session cleared. You can now run ExWapp.Example.run() to pair again.")
        :ok

      {:error, reason, path} ->
        IO.puts("❌ Failed to clear session: #{inspect(reason)} at #{path}")
        {:error, reason}
    end
  end

  @doc """
  Boots a new session, starts the connection and saves QR code to file.
  Automatically clears session and retries on 401 (unauthorized) errors.
  """
  def run(opts \\ []) do
    IO.puts("Starting WhatsApp pairing...")

    # Ensure directory exists
    File.mkdir_p!(Path.dirname(@store_path))

    # Start session with persistent storage - reconnect enabled for QR retries
    store_opts = Keyword.get(opts, :store, {ExWapp.Store.Ets, path: @store_path})
    {:ok, session} = ExWapp.start_link(store: store_opts)

    # Check current state
    case ExWapp.state(session) do
      :idle ->
        :ok = ExWapp.connect(session)
        result = wait_for_pairing(session)

        # Handle 401 error by clearing session and retrying
        case result do
          {:error, :unauthorized} ->
            IO.puts("\n🔄 Session expired or logged out. Clearing and restarting...")
            GenServer.stop(session, :normal)
            clear_session()
            Process.sleep(1000)
            run(opts)

          _ ->
            {:ok, session}
        end

      _other ->
        IO.puts("Session already connected or connecting")
        {:ok, session}
    end
  end

  defp wait_for_pairing(session) do
    IO.puts("Waiting for QR code...\n")

    # Monitor the session to detect crashes/disconnects
    ref = Process.monitor(session)

    result =
      session
      |> ExWapp.qr_stream()
      |> Enum.reduce_while({false, :ok}, fn event, {qr_saved, _status} ->
        case event do
          {:code, code} ->
            # Only save the first QR code
            if not qr_saved do
              save_qr(code)
              {:cont, {true, :ok}}
            else
              IO.puts("QR refreshed - check #{@qr_path}")
              {:cont, {true, :ok}}
            end

          :success ->
            IO.puts("\n✅ Paired successfully!")

            # Wait for 515 reconnect to complete and connection to stabilize
            IO.puts("Waiting for connection to stabilize...")
            wait_for_connected(session, 10)

            # Demo: List chats and send a test message
            demo_send_message(session)

            IO.puts("Keeping session alive... Press Ctrl+C to exit.")
            # Keep the session running
            keep_alive(session)
            {:halt, {true, :ok}}

          {:error, :timeout} ->
            IO.puts("\n⏱️  Timeout - QR code expired")
            {:halt, {true, {:error, :timeout}}}

          {:error, :unauthorized} ->
            IO.puts("\n🚫 Session unauthorized (401) - device was logged out")
            {:halt, {true, {:error, :unauthorized}}}

          {:error, :session_invalid} ->
            IO.puts("\n🚫 Session invalid - device was logged out")
            {:halt, {true, {:error, :unauthorized}}}

          {:error, {:failure, "401", _location}} ->
            IO.puts("\n🚫 Session unauthorized (401) - device was logged out")
            {:halt, {true, {:error, :unauthorized}}}

          {:error, reason} ->
            # Check if it's a 401 error
            if is_401_error?(reason) do
              IO.puts("\n🚫 Session unauthorized (401) - device was logged out")
              {:halt, {true, {:error, :unauthorized}}}
            else
              IO.puts("\n❌ Error: #{inspect(reason)}")
              {:halt, {true, {:error, reason}}}
            end
        end
      end)

    Process.demonitor(ref, [:flush])

    case result do
      {_, status} -> status
      other -> other
    end
  end

  defp is_401_error?(reason) do
    case reason do
      {:failure, "401", _} -> true
      {:failure, 401, _} -> true
      :unauthorized -> true
      :session_invalid -> true
      "401" -> true
      401 -> true
      _ -> false
    end
  end

  defp demo_send_message(session) do
    IO.puts("\n📱 Session ready!")
    IO.puts("Note: Chat history sync requires Signal decryption (not fully implemented)")

    # Get own JID for sending test message
    case get_own_jid(session) do
      {:ok, own_jid} ->
        IO.puts("\n📤 Sending test message to self: #{own_jid}")

        case ExWapp.send_message(session, own_jid, "ciao from ExWapp!") do
          {:ok, msg_id} ->
            IO.puts("✅ Message sent! ID: #{msg_id}")
            IO.puts("\n💬 Check your WhatsApp - you should see the message in 'You' chat!")

          {:error, reason} ->
            IO.puts("❌ Failed to send message: #{inspect(reason)}")
        end

      {:error, _} ->
        IO.puts("⚠️  Couldn't get own JID")
    end

    IO.puts("\n📝 To send a message manually:")
    IO.puts("   ExWapp.send_message(session, \"PHONE@s.whatsapp.net\", \"Hello!\")")
    IO.puts("   Example: ExWapp.send_message(session, \"1234567890@s.whatsapp.net\", \"Hi!\")")
  end

  defp wait_for_connected(session, max_attempts) do
    wait_for_connected(session, max_attempts, 0)
  end

  defp wait_for_connected(_session, max_attempts, attempts) when attempts >= max_attempts do
    IO.puts("⚠️  Connection didn't stabilize after #{max_attempts} attempts")
    :timeout
  end

  defp wait_for_connected(session, max_attempts, attempts) do
    Process.sleep(1000)

    # Use a short timeout to avoid blocking
    status =
      try do
        GenServer.call(session, :get_status, 2000)
      catch
        :exit, _ -> :unknown
      end

    case status do
      :connected ->
        IO.puts("✅ Connection ready!")
        # Wait a bit more for any offline messages
        Process.sleep(2000)
        :ok

      :unknown ->
        IO.puts("  Session busy, waiting... (#{attempts + 1}/#{max_attempts})")
        wait_for_connected(session, max_attempts, attempts + 1)

      other ->
        IO.puts("  Connection status: #{other}, waiting... (#{attempts + 1}/#{max_attempts})")
        wait_for_connected(session, max_attempts, attempts + 1)
    end
  end

  defp get_own_jid(session) do
    try do
      store = GenServer.call(session, :get_store)
      data = ExWapp.Store.load!(store)

      case get_in(data, [:pairing, :device, "jid"]) do
        %ExWapp.JID{user: user} = _jid when is_binary(user) ->
          # Use just the user part (without device number) for sending
          {:ok, "#{user}@s.whatsapp.net"}

        jid when is_binary(jid) ->
          # Extract user part if it's a string like "123:5@s.whatsapp.net"
          case String.split(jid, [":", "@"]) do
            [user | _] -> {:ok, "#{user}@s.whatsapp.net"}
            _ -> {:ok, jid}
          end

        _ ->
          {:error, :no_jid}
      end
    catch
      _, _ -> {:error, :failed}
    end
  end

  defp save_qr(code) when is_binary(code) do
    IO.puts("QR Data: #{code}")
    IO.puts("QR Data length: #{byte_size(code)} bytes")

    # Parse and validate the QR data format
    parts = String.split(code, ",")
    IO.puts("QR parts count: #{length(parts)}")

    case parts do
      [ref, noise, identity, adv] ->
        IO.puts("  ref: #{ref}")
        IO.puts("  noise (#{byte_size(noise)} chars): #{String.slice(noise, 0, 20)}...")
        IO.puts("  identity (#{byte_size(identity)} chars): #{String.slice(identity, 0, 20)}...")
        IO.puts("  adv (#{byte_size(adv)} chars): #{String.slice(adv, 0, 20)}...")

      _ ->
        IO.puts("  Invalid format - expected 4 comma-separated parts")
    end

    # Generate and save QR code using qr_code library
    result =
      code
      |> QRCode.create(:high)
      |> QRCode.render()
      |> QRCode.save(@qr_path)

    case result do
      {:ok, path} ->
        IO.puts("\n✅ QR code saved to: #{path}")
        IO.puts("Open the file in a browser to scan with WhatsApp.")

      {:error, reason} ->
        IO.puts("❌ Failed to save QR code: #{inspect(reason)}")
    end
  rescue
    e ->
      IO.puts("[EXAMPLE] QR save failed: #{inspect(e)}")
      IO.puts("Raw QR data: #{code}")
  end

  defp keep_alive(session) do
    # Wait indefinitely, responding to messages
    receive do
      {:DOWN, _ref, :process, ^session, reason} ->
        IO.puts("Session terminated: #{inspect(reason)}")
    after
      60_000 ->
        IO.puts("Session still active...")
        keep_alive(session)
    end
  end

  # ============================================================================
  # Signal Implementation Helpers
  # ============================================================================

  @doc """
  Shows info about the current Signal implementation.
  """
  def signal_info do
    info = ExWapp.Signal.Adapter.info()

    IO.puts("\n📡 Signal Protocol Configuration:")
    IO.puts("  Current implementation: #{info.impl}")
    IO.puts("  Module: #{info.module}")
    IO.puts("  Native available: #{info.native_available}")
    IO.puts("  Elixir available: #{info.elixir_available}")

    info
  end

  @doc """
  Switch to the Rust NIF Signal implementation (default).
  """
  def use_native_signal do
    ExWapp.Signal.Adapter.set_impl(:native)
    IO.puts("✅ Switched to Native (Rust) Signal implementation")
    :ok
  end

  @doc """
  Switch to the pure Elixir Signal implementation (fallback).
  """
  def use_elixir_signal do
    ExWapp.Signal.Adapter.set_impl(:elixir)
    IO.puts("✅ Switched to Elixir Signal implementation")
    :ok
  end

  @doc """
  Test the Signal implementation by generating keys and encrypting a test message.
  """
  def test_signal do
    alias ExWapp.Signal.Adapter, as: Signal

    IO.puts("\n🔐 Testing Signal implementation: #{Signal.get_impl()}")

    # Generate keys
    {pub, _priv} = Signal.generate_key_pair()
    IO.puts("  ✓ Key generation: #{byte_size(pub)} bytes")

    # Test signature verification (if native)
    case Signal.get_impl() do
      :native ->
        {_, priv} = ExWapp.Signal.Native.generate_key_pair()
        {spk_pub, _spk_priv, sig} = ExWapp.Signal.Native.generate_signed_prekey(priv)
        valid = ExWapp.Signal.Native.verify_signature(pub, spk_pub, sig)
        IO.puts("  ✓ Signature: #{if valid, do: "valid", else: "INVALID"}")

      :elixir ->
        IO.puts("  ✓ Signature: skipped (elixir)")
    end

    IO.puts("  ✓ All tests passed!")
    :ok
  end

  @doc """
  Test sending a message using the new v2 session cipher (complete Rust implementation).

  This bypasses the complex Elixir session management and uses the wacore-ported
  Rust implementation directly.

  Usage:
      iex> {:ok, session} = ExWapp.Example.run()
      iex> ExWapp.Example.send_v2(session, "393791383728@s.whatsapp.net", "Hello!")
      iex> ExWapp.Example.send_v2(session, "393791383728@s.whatsapp.net", "Hello!", 40)
  """
  def send_v2(session, jid, text, device_id \\ nil) do
    alias ExWapp.{Store, Conn}
    alias ExWapp.Signal.NativeSession

    # Handle device ID targeting
    jid =
      if device_id do
        [user, server] = String.split(jid, "@")
        "#{user}:#{device_id}@#{server}"
      else
        jid
      end

    IO.puts("\n🔐 Sending with V2 Session Cipher (complete Rust)")
    IO.puts("   To: #{jid}")
    IO.puts("   Text: #{text}")

    # Get store and connection from session
    store = GenServer.call(session, :get_store)
    conn = GenServer.call(session, :get_conn)

    # Load our identity and registration ID
    data = Store.load!(store)
    signal_data = Map.get(data, :signal, %{})
    local_identity = Map.get(signal_data, :identity_key)
    local_reg_id = Map.get(signal_data, :registration_id, 0)

    if !local_identity do
      IO.puts("❌ No identity key found!")
      {:error, :no_identity}
    else
      IO.puts("   Local reg_id: #{local_reg_id}")

      # Fetch prekeys for recipient
      IO.puts("   Fetching prekeys...")

      case fetch_prekeys(session, jid) do
        {:ok, bundle} ->
          IO.puts(
            "   ✓ Got bundle: reg_id=#{bundle.registration_id}, spk_id=#{bundle.signed_prekey.id}"
          )

          # Create session using v2 cipher
          {:ok, session_data} =
            NativeSession.create_session_v2(
              local_identity,
              local_reg_id,
              bundle
            )

          # Build and pad message
          proto = ExWapp.Messages.build_text_proto(text, [])
          {:ok, payload} = ExWapp.Proto.Message.encode(proto)
          padded_payload = ExWapp.Signal.Encryption.pad_message(payload)

          IO.puts(
            "   Payload: #{byte_size(payload)} bytes, padded: #{byte_size(padded_payload)} bytes"
          )

          # Encrypt using v2 cipher
          {:ok, encrypted, enc_type, _new_session} =
            NativeSession.encrypt_v2(session_data, padded_payload)

          IO.puts("   ✓ Encrypted: #{byte_size(encrypted)} bytes")
          IO.puts("   First 8 bytes: #{Base.encode16(binary_part(encrypted, 0, 8))}")

          # Build and send message node
          message_id = ExWapp.Messages.generate_id()
          timestamp = System.system_time(:second)

          # Get signed device identity for the message
          # This is stored in the pairing data, NOT the identity key
          pairing_data = Map.get(data, :pairing, %{})

          device_identity =
            Map.get(pairing_data, :device_identity) ||
              Map.get(pairing_data, :adv_device_identity)

          message_node =
            build_message_node_v2(
              jid,
              message_id,
              timestamp,
              encrypted,
              enc_type,
              device_identity
            )

          IO.puts("   Sending...")

          case Conn.send_node(conn, message_node) do
            :ok ->
              IO.puts("   ✅ Message sent! ID: #{message_id}")
              {:ok, message_id}

            error ->
              IO.puts("   ❌ Send failed: #{inspect(error)}")
              error
          end

        {:error, reason} ->
          IO.puts("   ❌ Failed to fetch prekeys: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp fetch_prekeys(session, jid) do
    alias ExWapp.Binary

    # Build prekey request
    message_id = ExWapp.Messages.generate_id()

    request_node = %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "encrypt",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [
        %Binary.Node{
          tag: "key",
          attrs: %{},
          content: [
            %Binary.Node{
              tag: "user",
              attrs: %{"jid" => jid},
              content: nil
            }
          ]
        }
      ]
    }

    # Use session's IQ handling which properly routes responses
    case GenServer.call(session, {:send_iq, request_node, message_id}, 30_000) do
      {:ok, response} ->
        parse_prekey_response(response)

      error ->
        error
    end
  end

  defp parse_prekey_response(%ExWapp.Binary.Node{
         tag: "iq",
         attrs: %{"type" => "result"},
         content: content
       })
       when is_list(content) do
    case find_child(content, "list") do
      %ExWapp.Binary.Node{content: users} when is_list(users) ->
        case Enum.find(users, &match?(%ExWapp.Binary.Node{tag: "user"}, &1)) do
          %ExWapp.Binary.Node{} = user_node ->
            parse_user_prekey_bundle(user_node)

          nil ->
            {:error, :no_user_in_response}
        end

      _ ->
        {:error, :no_list_in_response}
    end
  end

  defp parse_prekey_response(_), do: {:error, :invalid_response}

  defp parse_user_prekey_bundle(%ExWapp.Binary.Node{attrs: _attrs, content: content})
       when is_list(content) do
    registration = find_child(content, "registration")
    registration_id = if registration, do: parse_binary_int(registration.content), else: 0

    identity = find_child(content, "identity")
    identity_key = if identity, do: extract_binary(identity.content), else: nil

    skey = find_child(content, "skey")
    signed_prekey = if skey, do: parse_signed_prekey_node(skey), else: nil

    key = find_child(content, "key")
    one_time_prekey = if key, do: parse_prekey_node(key), else: nil

    if identity_key && signed_prekey do
      {:ok,
       %{
         registration_id: registration_id,
         identity_key: identity_key,
         signed_prekey: signed_prekey,
         prekey: one_time_prekey
       }}
    else
      {:error, :incomplete_bundle}
    end
  end

  defp parse_user_prekey_bundle(_), do: {:error, :invalid_user_node}

  defp parse_signed_prekey_node(%ExWapp.Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")
    sig_node = find_child(content, "signature")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary(value_node.content), else: nil
    signature = if sig_node, do: extract_binary(sig_node.content), else: nil

    if public && signature, do: %{id: id, public: public, signature: signature}, else: nil
  end

  defp parse_signed_prekey_node(_), do: nil

  defp parse_prekey_node(%ExWapp.Binary.Node{content: content}) when is_list(content) do
    id_node = find_child(content, "id")
    value_node = find_child(content, "value")

    id = if id_node, do: parse_key_id(id_node.content), else: 0
    public = if value_node, do: extract_binary(value_node.content), else: nil

    if public, do: %{id: id, public: public}, else: nil
  end

  defp parse_prekey_node(_), do: nil

  defp find_child(content, tag) when is_list(content) do
    Enum.find(content, fn
      %ExWapp.Binary.Node{tag: ^tag} -> true
      _ -> false
    end)
  end

  defp find_child(_, _), do: nil

  defp extract_binary(%ExWapp.Binary.Raw{data: data}), do: data
  defp extract_binary(data) when is_binary(data), do: data
  defp extract_binary(_), do: nil

  defp parse_binary_int(%ExWapp.Binary.Raw{data: data}) when byte_size(data) >= 4 do
    <<val::32>> = binary_part(data, 0, 4)
    val
  end

  defp parse_binary_int(_), do: 0

  defp parse_key_id(%ExWapp.Binary.Raw{data: data}) when byte_size(data) == 3 do
    <<id::24>> = data
    id
  end

  defp parse_key_id(%ExWapp.Binary.Raw{data: data}) when byte_size(data) >= 3 do
    <<id::24>> = binary_part(data, 0, 3)
    id
  end

  defp parse_key_id(_), do: 0

  defp build_message_node_v2(jid, message_id, timestamp, encrypted, enc_type, device_identity) do
    alias ExWapp.Binary

    type_str =
      case enc_type do
        :prekey -> "pkmsg"
        "pkmsg" -> "pkmsg"
        _ -> "msg"
      end

    # Strip device suffix for the outer message "to" attribute
    base_jid = String.replace(jid, ~r/:.+@/, "@")

    enc_node = %Binary.Node{
      tag: "enc",
      attrs: %{"type" => type_str, "v" => "2"},
      content: %Binary.Raw{data: encrypted}
    }

    to_node = %Binary.Node{
      tag: "to",
      attrs: %{"jid" => jid},
      content: [enc_node]
    }

    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: [to_node]
    }

    content =
      if device_identity do
        device_identity_node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: %Binary.Raw{data: device_identity}
        }

        [participants_node, device_identity_node]
      else
        [participants_node]
      end

    %Binary.Node{
      tag: "message",
      attrs: %{
        "id" => message_id,
        "type" => "text",
        "to" => base_jid,
        "t" => Integer.to_string(timestamp)
      },
      content: content
    }
  end

  # ============================================================================
  # V3: Multi-device support
  # ============================================================================

  @doc """
  Send a message with full multi-device support.

  This function:
  1. Fetches device list for recipient and sender via usync
  2. Encrypts message for ALL recipient devices
  3. Encrypts DeviceSentMessage for all sender's OTHER devices
  4. Sends a single message with all encrypted payloads

  Usage:
      iex> ExWapp.Example.send_v3(session, "393667330039@s.whatsapp.net", "Hello!")
  """
  def send_v3(session, recipient_jid, text) do
    alias ExWapp.{Store, Conn}
    alias ExWapp.Signal.NativeSession

    IO.puts("\n🔐 Sending with V3 Multi-Device")
    IO.puts("   To: #{recipient_jid}")
    IO.puts("   Text: #{text}")

    # Get store and connection from session
    store = GenServer.call(session, :get_store)
    conn = GenServer.call(session, :get_conn)

    # Load our data
    data = Store.load!(store)
    signal_data = Map.get(data, :signal, %{})
    local_identity = Map.get(signal_data, :identity_key)
    local_reg_id = Map.get(signal_data, :registration_id, 0)

    # Get our own JID
    own_jid = get_in(data, [:pairing, :device, "jid"])
    own_user = if own_jid, do: "#{own_jid.user}@#{own_jid.server}", else: nil
    own_device = if own_jid, do: own_jid.device, else: nil

    if !local_identity || !own_jid do
      IO.puts("❌ Missing identity or JID!")
      {:error, :not_configured}
    else
      IO.puts("   Own JID: #{own_user}, device: #{own_device}")
      IO.puts("   Local reg_id: #{local_reg_id}")

      # Step 1: Get device list for recipient and self
      IO.puts("   Fetching device lists...")

      recipient_user = recipient_jid |> String.split("@") |> List.first()
      jids_to_query = [recipient_jid]
      # Also query own devices if sending to someone else
      jids_to_query =
        if recipient_user != own_jid.user do
          jids_to_query ++ [own_user]
        else
          jids_to_query
        end

      case get_user_devices(session, jids_to_query) do
        {:ok, device_map} ->
          recipient_devices = Map.get(device_map, recipient_user, [])
          own_devices = Map.get(device_map, own_jid.user, []) |> Enum.reject(&(&1 == own_device))

          IO.puts("   ✓ Recipient devices: #{inspect(recipient_devices)}")
          IO.puts("   ✓ Own other devices: #{inspect(own_devices)}")

          recipient_devices =
            if recipient_devices == [] do
              IO.puts("   ⚠ No devices found for recipient, trying device 0")
              [0]
            else
              recipient_devices
            end

          # Build the message proto
          proto = ExWapp.Messages.build_text_proto(text, [])
          {:ok, payload} = ExWapp.Proto.Message.encode(proto)
          padded_payload = ExWapp.Signal.Encryption.pad_message(payload)

          # Skip own devices for now - DeviceSentMessage proto not implemented
          # TODO: Implement DeviceSentMessage encoding
          own_devices = []

          # Get device identity for prekey messages
          pairing_data = Map.get(data, :pairing, %{})

          device_identity =
            Map.get(pairing_data, :device_identity) ||
              Map.get(pairing_data, :adv_device_identity)

          # Step 2: Encrypt for all recipient devices
          IO.puts("   Encrypting for recipient devices...")

          recipient_nodes =
            encrypt_for_devices(
              session,
              recipient_jid,
              recipient_devices,
              padded_payload,
              local_identity,
              local_reg_id
            )

          # Step 3: Own devices skipped (DeviceSentMessage not implemented)
          own_nodes = []

          all_to_nodes = recipient_nodes ++ own_nodes

          if all_to_nodes == [] do
            IO.puts("   ❌ No encryptions succeeded!")
            {:error, :no_encryptions}
          else
            # Step 4: Build and send message node
            message_id = ExWapp.Messages.generate_id()
            timestamp = System.system_time(:second)

            # Check if any prekey messages were sent
            has_prekey =
              Enum.any?(all_to_nodes, fn node ->
                case node do
                  %{content: [%{attrs: %{"type" => "pkmsg"}}]} -> true
                  _ -> false
                end
              end)

            message_node =
              build_multi_device_message_node(
                recipient_jid,
                message_id,
                timestamp,
                all_to_nodes,
                if(has_prekey, do: device_identity, else: nil)
              )

            IO.puts("   Sending to #{length(all_to_nodes)} devices...")

            case Conn.send_node(conn, message_node) do
              :ok ->
                IO.puts("   ✅ Message sent! ID: #{message_id}")
                {:ok, message_id}

              error ->
                IO.puts("   ❌ Send failed: #{inspect(error)}")
                error
            end
          end

        {:error, reason} ->
          IO.puts("   ❌ Failed to get devices: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp get_user_devices(session, jids) do
    alias ExWapp.Binary

    # Build usync query
    message_id = ExWapp.Messages.generate_id()
    sid = ExWapp.Messages.generate_id()

    user_nodes =
      Enum.map(jids, fn jid ->
        %Binary.Node{
          tag: "user",
          attrs: %{"jid" => jid},
          content: nil
        }
      end)

    usync_node = %Binary.Node{
      tag: "usync",
      attrs: %{
        "sid" => sid,
        "mode" => "query",
        "last" => "true",
        "index" => "0",
        "context" => "message"
      },
      content: [
        %Binary.Node{
          tag: "query",
          attrs: %{},
          content: [
            %Binary.Node{
              tag: "devices",
              attrs: %{"version" => "2"},
              content: nil
            }
          ]
        },
        %Binary.Node{
          tag: "list",
          attrs: %{},
          content: user_nodes
        }
      ]
    }

    request_node = %Binary.Node{
      tag: "iq",
      attrs: %{
        "id" => message_id,
        "xmlns" => "usync",
        "type" => "get",
        "to" => "s.whatsapp.net"
      },
      content: [usync_node]
    }

    case GenServer.call(session, {:send_iq, request_node, message_id}, 30_000) do
      {:ok, response} ->
        parse_usync_response(response)

      error ->
        error
    end
  end

  defp parse_usync_response(%ExWapp.Binary.Node{
         tag: "iq",
         attrs: %{"type" => "result"},
         content: content
       }) do
    alias ExWapp.Binary

    # Find usync > list > user nodes
    case find_child(content, "usync") do
      %Binary.Node{content: usync_content} ->
        case find_child(usync_content, "list") do
          %Binary.Node{content: users} when is_list(users) ->
            device_map =
              Enum.reduce(users, %{}, fn
                %Binary.Node{tag: "user", attrs: attrs, content: user_content}, acc ->
                  jid = Map.get(attrs, "jid")

                  user =
                    case jid do
                      %ExWapp.JID{user: u} -> u
                      jid when is_binary(jid) -> jid |> String.split("@") |> List.first()
                      _ -> nil
                    end

                  if user do
                    devices = parse_device_list(user_content)
                    Map.put(acc, user, devices)
                  else
                    acc
                  end

                _, acc ->
                  acc
              end)

            {:ok, device_map}

          _ ->
            {:ok, %{}}
        end

      _ ->
        {:ok, %{}}
    end
  end

  defp parse_usync_response(_), do: {:error, :invalid_response}

  defp parse_device_list(nil), do: []

  defp parse_device_list(content) when is_list(content) do
    alias ExWapp.Binary

    case find_child(content, "devices") do
      %Binary.Node{content: devices_content} ->
        case find_child(devices_content, "device-list") do
          %Binary.Node{content: device_nodes} when is_list(device_nodes) ->
            Enum.flat_map(device_nodes, fn
              %Binary.Node{tag: "device", attrs: attrs} ->
                case Map.get(attrs, "id") do
                  id when is_integer(id) -> [id]
                  id when is_binary(id) -> [String.to_integer(id)]
                  _ -> []
                end

              _ ->
                []
            end)

          _ ->
            []
        end

      _ ->
        []
    end
  end

  defp parse_device_list(_), do: []

  defp encrypt_for_devices(session, base_jid, device_ids, payload, local_identity, local_reg_id) do
    alias ExWapp.Signal.NativeSession

    # Get base user from JID (remove any device suffix)
    [user | _] = String.split(base_jid, [":", "@"])

    server =
      if String.contains?(base_jid, "@") do
        base_jid |> String.split("@") |> List.last()
      else
        "s.whatsapp.net"
      end

    Enum.flat_map(device_ids, fn device_id ->
      device_jid =
        if device_id == 0 do
          "#{user}@#{server}"
        else
          "#{user}:#{device_id}@#{server}"
        end

      case fetch_prekeys(session, device_jid) do
        {:ok, bundle} ->
          case NativeSession.create_session_v2(local_identity, local_reg_id, bundle) do
            {:ok, session_data} ->
              case NativeSession.encrypt_v2(session_data, payload) do
                {:ok, encrypted, enc_type, _} ->
                  IO.puts(
                    "     ✓ Encrypted for #{device_jid}: #{byte_size(encrypted)} bytes (#{enc_type})"
                  )

                  [build_to_node(device_jid, encrypted, enc_type)]

                {:error, reason} ->
                  IO.puts("     ✗ Encrypt failed for #{device_jid}: #{inspect(reason)}")
                  []
              end

            {:error, reason} ->
              IO.puts("     ✗ Session failed for #{device_jid}: #{inspect(reason)}")
              []
          end

        {:error, reason} ->
          IO.puts("     ✗ Prekeys failed for #{device_jid}: #{inspect(reason)}")
          []
      end
    end)
  end

  defp build_to_node(jid, encrypted, enc_type) do
    alias ExWapp.Binary
    type_str = if enc_type in [:prekey, "pkmsg"], do: "pkmsg", else: "msg"

    %Binary.Node{
      tag: "to",
      attrs: %{"jid" => jid},
      content: [
        %Binary.Node{
          tag: "enc",
          attrs: %{"type" => type_str, "v" => "2"},
          content: %Binary.Raw{data: encrypted}
        }
      ]
    }
  end

  defp build_device_sent_message(destination_jid, original_message) do
    %{
      deviceSentMessage: %{
        destinationJid: destination_jid,
        message: original_message
      },
      messageContextInfo: Map.get(original_message, :messageContextInfo)
    }
  end

  defp build_multi_device_message_node(
         recipient_jid,
         message_id,
         timestamp,
         to_nodes,
         device_identity
       ) do
    alias ExWapp.Binary

    participants_node = %Binary.Node{
      tag: "participants",
      attrs: %{},
      content: to_nodes
    }

    content =
      if device_identity do
        device_identity_node = %Binary.Node{
          tag: "device-identity",
          attrs: %{},
          content: %Binary.Raw{data: device_identity}
        }

        [participants_node, device_identity_node]
      else
        [participants_node]
      end

    # Extract base recipient JID (without device suffix)
    base_jid =
      recipient_jid
      # Remove device ID if present
      |> String.replace(~r/:.*@/, "@")

    %Binary.Node{
      tag: "message",
      attrs: %{
        "id" => message_id,
        "type" => "text",
        "to" => base_jid,
        "t" => Integer.to_string(timestamp)
      },
      content: content
    }
  end
end
