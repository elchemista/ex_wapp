defmodule ExWapp.Media.HTTP do
  @moduledoc """
  Minimal WhatsApp media upload/download client.

  The session worker supplies IQ access through `opts[:session]`; this module
  queries `media_conn`, uploads encrypted media bodies, and downloads encrypted
  bodies that are later verified and decrypted by `ExWapp.Media.Crypto`.
  """

  alias ExWapp.{JSON, Media}
  alias ExWapp.Media.BoundedHTTP
  alias ExWapp.Session.IQ

  @origin "https://web.whatsapp.com"

  @doc """
  Encrypts plaintext media and uploads it to the best available media host.

  `:max_bytes` limits plaintext size (64 MiB by default). `:timeout` applies a
  shared request deadline of at most 60 seconds; the TLS connection timeout is
  capped at 10 seconds. `:session` supplies authenticated `media_conn` access.
  """
  @spec upload(map(), Media.media_type(), binary(), keyword()) ::
          {:ok, Media.Upload.t()} | {:error, term()}
  def upload(state, type, plaintext, opts \\ []) when is_binary(plaintext) do
    opts = request_options(opts)

    with :ok <- validate_size(byte_size(plaintext), opts),
         {:ok, upload, body} <- Media.Crypto.encrypt_upload(plaintext, type),
         {:ok, media_conn} <- media_conn(state, opts) do
      do_upload(media_conn, upload, body, opts)
    end
  end

  @doc """
  Downloads encrypted media and returns the decrypted plaintext bytes.

  Reads require HTTPS and authenticated media metadata, have a shared deadline
  controlled by `:timeout` (at most 60 seconds), and are bounded by `:max_bytes`
  (64 MiB by default). Known WhatsApp/CDN hosts and authenticated `media_conn`
  hosts are trusted; `:allowed_media_origins` explicitly adds HTTPS origins.
  Plaintext media requires `:allow_plaintext` and a valid plaintext SHA-256 hash.
  """
  @spec download(map(), Media.Ref.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  def download(state, %Media.Ref{} = ref, opts \\ []) do
    opts = request_options(opts)

    with :ok <- validate_download_ref(ref, opts),
         {:ok, body} <- fetch_encrypted_body(state, ref, opts),
         {:ok, plaintext} <- Media.Crypto.decrypt_download(body, ref),
         :ok <- validate_size(byte_size(plaintext), opts) do
      {:ok, plaintext}
    end
  end

  @spec fetch_encrypted_body(map(), Media.Ref.t(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  defp fetch_encrypted_body(state, %Media.Ref{url: url} = ref, opts)
       when is_binary(url) and url != "" do
    case http_get(url, opts) do
      {:ok, body} ->
        {:ok, body}

      {:error, reason} = error when reason in [:timeout, :media_too_large] ->
        error

      {:error, _reason} = error ->
        if is_binary(ref.direct_path) and ref.direct_path != "",
          do: fetch_from_direct_path(state, %{ref | url: nil}, opts),
          else: error
    end
  end

  defp fetch_encrypted_body(state, ref, opts), do: fetch_from_direct_path(state, ref, opts)

  @spec fetch_from_direct_path(map(), Media.Ref.t(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  defp fetch_from_direct_path(state, ref, opts) do
    with {:ok, media_conn} <- media_conn(state, opts) do
      do_download(media_conn, ref, opts)
    end
  end

  @spec media_conn(map(), keyword()) :: {:ok, map()} | {:error, term()}
  defp media_conn(_state, opts) do
    case Keyword.get(opts, :media_conn) do
      conn when is_map(conn) ->
        {:ok, conn}

      _ ->
        query_media_conn(Keyword.get(opts, :session), opts[:deadline])
    end
  end

  @spec query_media_conn(pid() | term(), integer()) :: {:ok, map()} | {:error, term()}
  defp query_media_conn(session, deadline) when is_pid(session) do
    id = ExWapp.Messages.generate_id()
    node = IQ.build_media_conn_query(id)

    timeout = min(max(deadline - System.monotonic_time(:millisecond), 0), 30_000)

    result =
      if timeout > 0,
        do: GenServer.call(session, {:send_iq, node, id, timeout}, timeout),
        else: {:error, :timeout}

    case result do
      {:ok, response} -> IQ.parse_media_conn_response(response)
      {:error, reason} -> {:error, reason}
      other -> {:error, {:bad_media_conn_response, other}}
    end
  end

  defp query_media_conn(_, _deadline), do: {:error, :missing_session_for_media_conn}

  @spec do_upload(map(), Media.Upload.t(), binary(), keyword()) ::
          {:ok, Media.Upload.t()} | {:error, term()}
  defp do_upload(%{hosts: [%{hostname: host} | _], auth: auth}, upload, body, opts) do
    opts = trust_media_hosts(opts, [%{hostname: host}])
    token = Base.url_encode64(upload.file_enc_sha256)
    mms_type = mms_type(upload.type)

    url = "https://#{host}/mms/#{mms_type}/#{token}?auth=#{uri(auth)}&token=#{uri(token)}"

    headers = [
      {~c"origin", String.to_charlist(@origin)},
      {~c"referer", String.to_charlist(@origin <> "/")},
      {~c"content-type", ~c"application/octet-stream"}
    ]

    with :ok <- validate_url(url, opts),
         {:ok, _status, response_body} <-
           BoundedHTTP.request(:post, url, headers, body, 1_048_576, opts[:deadline]) do
      {:ok, struct(upload, parse_upload_response(response_body))}
    else
      {:error, {:http_status, status}} -> {:error, {:upload_http_error, status, 0}}
      {:error, reason} -> {:error, {:upload_failed, reason}}
    end
  end

  defp do_upload(_media_conn, _upload, _body, _opts), do: {:error, :missing_media_host}

  @spec do_download(map(), Media.Ref.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  defp do_download(%{hosts: hosts}, %Media.Ref{url: url} = ref, opts)
       when is_binary(url) and url != "" do
    try_download_urls([url], hosts, ref, trust_media_hosts(opts, hosts))
  end

  defp do_download(%{hosts: hosts}, %Media.Ref{direct_path: direct_path} = ref, opts)
       when is_binary(direct_path) and direct_path != "" do
    hash = Base.url_encode64(ref.file_enc_sha256 || <<>>)
    mms_type = mms_type(ref.type)
    separator = if String.contains?(direct_path, "?"), do: "&", else: "?"

    # When the full CDN URL is missing, we reconstruct candidates from `media_conn`
    # hosts plus the server-provided direct path.
    urls =
      Enum.map(hosts, fn %{hostname: host} ->
        "https://#{host}#{direct_path}#{separator}hash=#{hash}&mms-type=#{mms_type}&__wa-mms="
      end)

    try_download_urls(urls, hosts, ref, trust_media_hosts(opts, hosts))
  end

  defp do_download(_media_conn, _ref, _opts), do: {:error, :missing_media_url}

  @spec try_download_urls([binary()], list(), Media.Ref.t(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  defp try_download_urls([], _hosts, _ref, _opts), do: {:error, :media_download_failed}

  defp try_download_urls([url | rest], hosts, ref, opts) do
    case http_get(url, opts) do
      {:ok, body} -> {:ok, body}
      {:error, _reason} when rest != [] -> try_download_urls(rest, hosts, ref, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec http_get(String.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  defp http_get(url, opts) do
    headers = [{"origin", @origin}, {"referer", @origin <> "/"}]

    with :ok <- validate_url(url, opts),
         {:ok, _status, body} <-
           BoundedHTTP.request(:get, url, headers, <<>>, opts[:max_bytes] + 26, opts[:deadline]) do
      {:ok, body}
    else
      {:error, {:http_status, status}} ->
        {:error, {:download_http_error, status, 0}}

      {:error, reason} = error
      when reason in [:timeout, :media_too_large, :untrusted_media_url] ->
        error

      {:error, reason} ->
        {:error, {:download_failed, reason}}
    end
  end

  @spec request_options(keyword()) :: keyword()
  defp request_options(opts) do
    now = System.monotonic_time(:millisecond)
    timeout = Keyword.get(opts, :timeout, 60_000)
    timeout = if is_integer(timeout) and timeout > 0, do: min(timeout, 60_000), else: 60_000
    deadline = Keyword.get(opts, :send_deadline)
    deadline = if is_integer(deadline), do: min(deadline, now + timeout), else: now + timeout
    max_bytes = Keyword.get(opts, :max_bytes, 64 * 1024 * 1024)
    max_bytes = if is_integer(max_bytes) and max_bytes > 0, do: max_bytes, else: 64 * 1024 * 1024
    opts = opts |> Keyword.put(:deadline, deadline) |> Keyword.put(:max_bytes, max_bytes)

    case Keyword.get(opts, :media_conn) do
      %{hosts: hosts} -> trust_media_hosts(opts, hosts)
      _ -> opts
    end
  end

  @spec trust_media_hosts(keyword(), [map()]) :: keyword()
  defp trust_media_hosts(opts, hosts) do
    origins = Enum.map(hosts, fn %{hostname: host} -> "https://" <> host end)
    Keyword.update(opts, :allowed_media_origins, origins, &(origins ++ &1))
  end

  @spec validate_download_ref(Media.Ref.t(), keyword()) :: :ok | {:error, atom()}
  defp validate_download_ref(ref, opts) do
    plaintext? =
      Keyword.get(opts, :allow_plaintext, false) == true and is_nil(ref.file_enc_sha256)

    with :ok <- validate_media_type(ref.type),
         :ok <- validate_required_hashes(ref, plaintext?),
         :ok <- validate_optional_hash(ref.file_sha256) do
      validate_size(ref.file_length, opts)
    end
  end

  @spec validate_media_type(term()) :: :ok | {:error, :unsupported_media_type}
  defp validate_media_type(type)
       when type in [:image, :video, :sticker, :audio, :document, :history],
       do: :ok

  defp validate_media_type(_type), do: {:error, :unsupported_media_type}

  @spec validate_required_hashes(Media.Ref.t(), boolean()) :: :ok | {:error, atom()}
  defp validate_required_hashes(ref, true) do
    if hash?(ref.file_sha256), do: :ok, else: {:error, :invalid_media_hash}
  end

  defp validate_required_hashes(ref, false) do
    cond do
      not hash?(ref.media_key) -> {:error, :invalid_media_key}
      not hash?(ref.file_enc_sha256) -> {:error, :invalid_encrypted_media_hash}
      true -> :ok
    end
  end

  @spec validate_optional_hash(term()) :: :ok | {:error, :invalid_media_hash}
  defp validate_optional_hash(nil), do: :ok

  defp validate_optional_hash(hash) do
    if hash?(hash), do: :ok, else: {:error, :invalid_media_hash}
  end

  @spec validate_size(term(), keyword()) :: :ok | {:error, atom()}
  defp validate_size(nil, _opts), do: :ok

  defp validate_size(size, opts) when is_integer(size) and size >= 0 do
    if size <= opts[:max_bytes], do: :ok, else: {:error, :media_too_large}
  end

  defp validate_size(_size, _opts), do: {:error, :invalid_media_length}

  @spec hash?(term()) :: boolean()
  defp hash?(hash), do: is_binary(hash) and byte_size(hash) == 32

  @spec validate_url(String.t(), keyword()) :: :ok | {:error, :untrusted_media_url}
  defp validate_url(url, opts) do
    case URI.parse(url) do
      %URI{scheme: "https", host: host, port: port, userinfo: nil, fragment: nil}
      when is_binary(host) ->
        host = String.downcase(host)

        known? = known_media_host?(host, port)
        trusted? = trusted_media_host?(host, port, opts)

        if (known? or trusted?) and not String.contains?(url, ["\r", "\n", "\0"]),
          do: :ok,
          else: {:error, :untrusted_media_url}

      _ ->
        {:error, :untrusted_media_url}
    end
  rescue
    _ -> {:error, :untrusted_media_url}
  end

  @spec known_media_host?(String.t(), non_neg_integer() | nil) :: boolean()
  defp known_media_host?(host, 443) do
    Enum.any?(["whatsapp.net", "whatsapp.com", "fbcdn.net"], fn suffix ->
      host == suffix or String.ends_with?(host, "." <> suffix)
    end)
  end

  defp known_media_host?(_host, _port), do: false

  @spec trusted_media_host?(String.t(), non_neg_integer() | nil, keyword()) :: boolean()
  defp trusted_media_host?(host, port, opts) do
    Enum.any?(Keyword.get(opts, :allowed_media_origins, []), &matching_origin?(&1, host, port))
  end

  @spec matching_origin?(String.t(), String.t(), non_neg_integer() | nil) :: boolean()
  defp matching_origin?(origin, host, port) do
    case URI.parse(origin) do
      %URI{scheme: "https", host: allowed, port: ^port} when is_binary(allowed) ->
        String.downcase(allowed) == host

      _ ->
        false
    end
  end

  @spec parse_upload_response(binary()) :: map()
  defp parse_upload_response(body) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, json} ->
        %{
          url: Map.get(json, "url"),
          direct_path: Map.get(json, "direct_path"),
          handle: Map.get(json, "handle"),
          object_id: Map.get(json, "object_id")
        }

      _ ->
        parse_upload_response_without_json(body)
    end
  end

  @spec parse_upload_response_without_json(binary()) :: map()
  defp parse_upload_response_without_json(body) do
    %{
      url: regex_capture(body, ~r/"url"\s*:\s*"([^"]+)"/),
      direct_path: regex_capture(body, ~r/"direct_path"\s*:\s*"([^"]+)"/),
      handle: regex_capture(body, ~r/"handle"\s*:\s*"([^"]+)"/),
      object_id: regex_capture(body, ~r/"object_id"\s*:\s*"([^"]+)"/)
    }
  end

  @spec regex_capture(binary(), Regex.t()) :: binary() | nil
  defp regex_capture(body, regex) do
    case Regex.run(regex, body) do
      [_all, value] -> value
      _ -> nil
    end
  end

  @spec mms_type(Media.download_type()) :: binary()
  defp mms_type(:image), do: "image"
  defp mms_type(:video), do: "video"
  defp mms_type(:sticker), do: "image"
  defp mms_type(:audio), do: "audio"
  defp mms_type(:document), do: "document"
  defp mms_type(:history), do: "md-msg-hist"

  @spec uri(term()) :: binary()
  defp uri(value), do: value |> to_string() |> URI.encode_www_form()
end
