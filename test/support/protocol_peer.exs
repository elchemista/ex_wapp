defmodule ExWapp.Test.ProtocolPeer do
  @moduledoc false
  alias ExWapp.Noise.{Certificate, Handshake}
  alias ExWapp.Signal.Keys
  alias ExWapp.Transport.Frame
  alias WAWebProtobufsWa6.HandshakeMessage
  alias WACert.CertChain
  alias WACert.CertChain.NoiseCertificate
  alias WACert.CertChain.NoiseCertificate.Details

  def new do
    root = Keys.generate_key_pair()
    intermediate = Keys.generate_key_pair()
    {static, static_private} = :crypto.generate_key(:ecdh, :x25519)
    {ephemeral, ephemeral_private} = :crypto.generate_key(:ecdh, :x25519)

    chain = %CertChain{
      intermediate:
        certificate(%Details{serial: 1, issuerSerial: 0, key: intermediate.public}, root.private),
      leaf: certificate(%Details{serial: 2, issuerSerial: 1, key: static}, intermediate.private)
    }

    %{
      root: root.public,
      certificate: encode(chain),
      static: static,
      static_private: static_private,
      ephemeral: ephemeral,
      ephemeral_private: ephemeral_private
    }
  end

  def verifier(peer),
    do: fn cert, static -> Certificate.verify(cert, static, root_key: peer.root) end

  def hello(peer, client_hello) do
    %{clientHello: %{ephemeral: client_ephemeral}} = HandshakeMessage.decode!(client_hello)

    hs =
      Handshake.new("Noise_XX_25519_AESGCM_SHA256\0\0\0\0", Frame.header())
      |> Handshake.authenticate(client_ephemeral)
      |> Handshake.authenticate(peer.ephemeral)

    {:ok, hs} = Handshake.mix_shared_secret(hs, peer.ephemeral_private, client_ephemeral)
    {hs, static} = Handshake.encrypt(hs, peer.static)
    {:ok, hs} = Handshake.mix_shared_secret(hs, peer.static_private, client_ephemeral)
    {hs, payload} = Handshake.encrypt(hs, peer.certificate)

    message = %HandshakeMessage{
      serverHello: %HandshakeMessage.ServerHello{
        ephemeral: peer.ephemeral,
        static: static,
        payload: payload
      }
    }

    {encode(message), Map.put(peer, :handshake, hs)}
  end

  def finish(peer, finish) do
    %{clientFinish: finish} = HandshakeMessage.decode!(finish)
    {:ok, hs, client_static} = Handshake.decrypt(peer.handshake, finish.static)
    {:ok, hs} = Handshake.mix_shared_secret(hs, peer.ephemeral_private, client_static)
    {:ok, hs, payload} = Handshake.decrypt(hs, finish.payload)
    {read, write} = Handshake.derive_transport_keys(hs)
    {%{read: read, write: write}, WAWebProtobufsWa6.ClientPayload.decode!(payload)}
  end

  def encrypt(key, counter, plain) do
    {cipher, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, key, <<0::64, counter::32>>, plain, <<>>, true)

    cipher <> tag
  end

  def decrypt(key, counter, cipher) do
    size = byte_size(cipher) - 16
    <<body::binary-size(^size), tag::binary-size(16)>> = cipher

    :crypto.crypto_one_time_aead(
      :aes_256_gcm,
      key,
      <<0::64, counter::32>>,
      body,
      <<>>,
      tag,
      false
    )
  end

  def unframe(<<"WA", 6, 3, rest::binary>>), do: unframe(rest)

  def unframe(payload) do
    {[frame], <<>>} = Frame.decode(payload)
    frame
  end

  def encode(message), do: message.__struct__.encode!(message) |> IO.iodata_to_binary()

  defp certificate(details, signer) do
    raw = encode(details)
    %NoiseCertificate{details: raw, signature: Keys.sign_message(signer, raw)}
  end
end

defmodule ExWapp.Test.ProtocolTransport do
  @moduledoc false
  use GenServer
  alias ExWapp.{Binary, Conn, Store}
  alias ExWapp.Binary.Node
  alias ExWapp.Test.ProtocolPeer, as: Peer
  alias ExWapp.Transport.Frame

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def send_node(pid, node), do: GenServer.call(pid, {:send, node})
  def restart_stream(pid), do: GenServer.cast(pid, :restart_stream)
  def inject(pid, node), do: GenServer.call(pid, {:receive, node})
  def set_reply(pid, fun), do: GenServer.call(pid, {:set_reply, fun})
  def fail_send(pid, tag, reason), do: GenServer.call(pid, {:fail_send, tag, reason})

  def init(opts) do
    peer = Peer.new()
    store = Keyword.fetch!(opts, :store)
    config = Store.get(store, :test_peer, %{})

    conn = %Conn.State{
      session: Keyword.fetch!(opts, :session),
      store: store,
      noise_opts:
        Keyword.put(Keyword.get(opts, :noise, []), :certificate_verifier, Peer.verifier(peer))
    }

    {:ok, conn} = Conn.handle_connect(nil, conn)
    {:ok, %{conn: conn, peer: peer, keys: nil, read: 0, write: 0, config: config}}
  end

  def handle_info({:send_raw_frame, {:binary, frame}}, state) do
    {hello, peer} = Peer.hello(state.peer, Peer.unframe(frame))

    {:ok, conn} =
      Conn.handle_frame({:binary, Frame.encode(hello, include_header: true)}, state.conn)

    {:noreply, %{state | peer: peer, conn: conn}}
  end

  def handle_info({:send_client_finish, _} = message, state) do
    {:reply, {:binary, frame}, conn} = Conn.handle_info(message, state.conn)
    {keys, payload} = Peer.finish(state.peer, Peer.unframe(frame))
    if owner = state.config[:owner], do: send(owner, {:peer_authenticated, self(), payload})
    state = %{state | keys: keys, conn: conn}

    state =
      if Map.get(state.config, :auto_success, true),
        do: receive_node(state, %Node{tag: "success", attrs: %{"t" => "1700000000"}}),
        else: state

    {:noreply, state}
  end

  def handle_info({:"$websockex_cast", {:send_node, node}}, state) do
    {:reply, :ok, state} = handle_call({:send, node}, nil, state)
    {:noreply, state}
  end

  def handle_info(message, state) do
    {:ok, conn} = Conn.handle_info(message, state.conn)
    {:noreply, %{state | conn: conn}}
  end

  def handle_call(
        {:send, %Node{tag: tag}},
        _from,
        %{config: %{send_error: {tag, reason}}} = state
      ),
      do: {:reply, {:error, reason}, state}

  def handle_call({:send, node}, _from, state) do
    {:reply, {:binary, frame}, conn} = Conn.handle_cast({:send_node, node}, state.conn)
    plain = Peer.decrypt(state.keys.read, state.read, Peer.unframe(frame))
    wire_node = Binary.decode!(plain)
    if owner = state.config[:owner], do: send(owner, {:peer_node, self(), wire_node})

    reply =
      case state.config[:reply] do
        nil ->
          default_reply(wire_node)

        fun ->
          case fun.(wire_node) do
            :default -> default_reply(wire_node)
            reply -> reply
          end
      end

    state = %{state | conn: conn, read: state.read + 1}
    state = if match?(%Node{}, reply), do: receive_node(state, reply), else: state
    {:reply, :ok, state}
  end

  def handle_call({:receive, node}, _from, state), do: {:reply, :ok, receive_node(state, node)}

  def handle_call({:set_reply, fun}, _from, state),
    do: {:reply, :ok, put_in(state.config[:reply], fun)}

  def handle_call({:fail_send, tag, reason}, _from, state),
    do: {:reply, :ok, put_in(state.config[:send_error], {tag, reason})}

  def handle_cast(:restart_stream, state), do: {:noreply, state}

  defp receive_node(state, node) do
    frame = Peer.encrypt(state.keys.write, state.write, Binary.encode!(node)) |> Frame.encode()
    {:ok, conn} = Conn.handle_frame({:binary, frame}, state.conn)
    %{state | conn: conn, write: state.write + 1}
  end

  defp default_reply(%Node{tag: "iq", attrs: %{"id" => id, "xmlns" => xmlns}, content: children}) do
    content =
      case {xmlns, children} do
        {"encrypt", [%Node{tag: "count"}]} ->
          [%Node{tag: "count", attrs: %{"value" => "100"}}]

        {"passive", _} ->
          nil

        {"w:sync:app:state",
         [%Node{tag: "sync", content: [%Node{tag: "collection", attrs: attrs}]}]} ->
          [
            %Node{
              tag: "sync",
              content: [%Node{tag: "collection", attrs: Map.take(attrs, ["name"])}]
            }
          ]

        _ ->
          :hold
      end

    if content == :hold,
      do: nil,
      else: %Node{tag: "iq", attrs: %{"id" => id, "type" => "result"}, content: content}
  end

  defp default_reply(_), do: nil
end

defmodule ExWapp.Test.SignalDevice do
  def pairing_success(store, jid) do
    alias ExWapp.Signal.Keys
    alias ExWapp.Binary.Node
    identity = ExWapp.Store.get(store, :signal).identity_key
    secret = ExWapp.Store.get(store, :adv_secret)
    account = Keys.generate_key_pair()

    details =
      ExWapp.Test.ProtocolPeer.encode(%WAAdv.ADVDeviceIdentity{
        rawID: 42,
        timestamp: 1_700_000_000,
        keyIndex: 7,
        accountType: :E2EE,
        deviceType: :E2EE
      })

    signed =
      ExWapp.Test.ProtocolPeer.encode(%WAAdv.ADVSignedDeviceIdentity{
        details: details,
        accountSignatureKey: account.public,
        accountSignature:
          Keys.sign_message(account.private, <<6, 0>> <> details <> identity.public)
      })

    blob =
      ExWapp.Test.ProtocolPeer.encode(%WAAdv.ADVSignedDeviceIdentityHMAC{
        details: signed,
        HMAC: :crypto.mac(:hmac, :sha256, secret, signed),
        accountType: :E2EE
      })

    %Node{
      tag: "iq",
      attrs: %{"id" => "pair-success", "type" => "set", "from" => "s.whatsapp.net"},
      content: [
        %Node{
          tag: "pair-success",
          content: [
            %Node{tag: "device-identity", content: %ExWapp.Binary.Raw{data: blob}},
            %Node{tag: "device", attrs: %{"jid" => jid}}
          ]
        }
      ]
    }
  end

  @moduledoc false
  alias ExWapp.Binary
  alias ExWapp.Binary.Node
  alias ExWapp.Signal.Keys

  def new do
    identity = Keys.generate_key_pair()
    signed = Keys.generate_signed_prekey(identity, 257)
    prekey = Keys.generate_prekey(65537)

    %{
      identity: identity,
      signed: signed,
      prekey: prekey,
      bundle: %{
        registration_id: 8193,
        identity_key: identity.public,
        signed_prekey: Map.take(signed, [:id, :public, :signature]),
        prekey: Map.take(prekey, [:id, :public])
      },
      local_prekeys: %{signed_prekeys: %{257 => signed}, prekeys: %{65537 => prekey}}
    }
  end

  def reply(device, %Node{
        tag: "iq",
        attrs: %{"id" => id, "xmlns" => "encrypt"},
        content: [%Node{tag: "key", content: users}]
      }) do
    %Node{
      tag: "iq",
      attrs: %{"id" => id, "type" => "result"},
      content: [
        %Node{tag: "list", content: Enum.map(users, &user(device, to_string(&1.attrs["jid"])))}
      ]
    }
  end

  def reply(_device, %Node{
        tag: "iq",
        attrs: %{"id" => id, "xmlns" => "usync"},
        content: [%Node{tag: "usync", content: children}]
      }) do
    users = Enum.find(children, &(&1.tag == "list")).content

    users =
      Enum.map(users, fn user ->
        %{
          user
          | content: [
              %Node{
                tag: "devices",
                content: [
                  %Node{
                    tag: "device-list",
                    content: [%Node{tag: "device", attrs: %{"id" => "0"}}]
                  }
                ]
              }
            ]
        }
      end)

    %Node{
      tag: "iq",
      attrs: %{"id" => id, "type" => "result"},
      content: [%Node{tag: "usync", content: [%Node{tag: "list", content: users}]}]
    }
  end

  def reply(_device, _node), do: :default

  def user(device, jid) do
    %Node{
      tag: "user",
      attrs: %{"jid" => jid},
      content: [
        raw("registration", <<8193::32>>),
        raw("identity", device.identity.public),
        raw("type", <<5>>),
        %Node{
          tag: "skey",
          content: [
            raw("id", <<257::24>>),
            raw("value", device.signed.public),
            raw("signature", device.signed.signature)
          ]
        },
        %Node{tag: "key", content: [raw("id", <<65537::24>>), raw("value", device.prekey.public)]}
      ]
    }
  end

  defp raw(tag, bytes), do: %Node{tag: tag, content: Binary.raw(bytes)}
end

defmodule ExWapp.Test.LocalHTTP do
  @moduledoc false
  use GenServer
  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def url(server), do: GenServer.call(server, :url)

  @impl true
  def init(opts) do
    {:ok, listener} =
      :gen_tcp.listen(0, [:binary, active: false, packet: :http_bin, ip: {127, 0, 0, 1}])

    {:ok, port} = :inet.port(listener)
    acceptor = spawn_link(fn -> accept_loop(listener, opts) end)
    {:ok, %{listener: listener, acceptor: acceptor, url: "http://127.0.0.1:#{port}"}}
  end

  @impl true
  def handle_call(:url, _from, state), do: {:reply, state.url, state}
  @impl true
  def terminate(_, state) do
    :gen_tcp.close(state.listener)
    Process.exit(state.acceptor, :shutdown)
  end

  defp accept_loop(listener, opts) do
    case :gen_tcp.accept(listener) do
      {:ok, socket} ->
        {:ok, request} = :gen_tcp.recv(socket, 0, 5_000)
        headers = headers(socket, %{})
        send(opts.owner, {:http_request, request, headers})
        {status, body} = opts.response

        :ok =
          :gen_tcp.send(socket, [
            "HTTP/1.1 #{status} Result\r\ncontent-length: #{byte_size(body)}\r\nconnection: close\r\n\r\n",
            body
          ])

        :gen_tcp.close(socket)
        accept_loop(listener, opts)

      {:error, :closed} ->
        :ok
    end
  end

  defp headers(socket, acc) do
    case :gen_tcp.recv(socket, 0, 5_000) do
      {:ok, :http_eoh} ->
        acc

      {:ok, {:http_header, _, key, _, value}} ->
        headers(socket, Map.put(acc, key |> to_string() |> String.downcase(), value))
    end
  end
end
