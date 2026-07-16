defmodule ExWapp.Media.HTTP do
  @moduledoc """
  Minimal WhatsApp media upload/download client.

  The session worker supplies IQ access through `opts[:session]`; this module
  queries `media_conn`, uploads encrypted media bodies, and downloads encrypted
  bodies that are later verified and decrypted by `ExWapp.Media.Crypto`.
  """

  alias ExWapp.Media
  alias ExWapp.Session.IQ
  alias ExWapp.Transport.TLS

  @origin "https://web.whatsapp.com"

  @doc """
  Encrypts plaintext media and uploads it to the best available media host.
  """
  @spec upload(map(), Media.media_type(), binary(), keyword()) ::
          {:ok, Media.Upload.t()} | {:error, term()}
  def upload(state, type, plaintext, opts \\ []) when is_binary(plaintext) do
    with {:ok, upload, body} <- Media.Crypto.encrypt_upload(plaintext, type),
         {:ok, media_conn} <- media_conn(state, opts) do
      do_upload(media_conn, upload, body)
    end
  end

  @doc """
  Downloads encrypted media and returns the decrypted plaintext bytes.
  """
  @spec download(map(), Media.Ref.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  def download(state, %Media.Ref{} = ref, opts \\ []) do
    with {:ok, body} <- fetch_encrypted_body(state, ref, opts) do
      Media.Crypto.decrypt_download(body, ref)
    end
  end

  @spec fetch_encrypted_body(map(), Media.Ref.t(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  defp fetch_encrypted_body(state, %Media.Ref{url: url} = ref, opts)
       when is_binary(url) and url != "" do
    case http_get(url) do
      {:ok, body} -> {:ok, body}
      {:error, _reason} -> fetch_from_direct_path(state, %{ref | url: nil}, opts)
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
        query_media_conn(Keyword.get(opts, :session))
    end
  end

  @spec query_media_conn(pid() | term()) :: {:ok, map()} | {:error, term()}
  defp query_media_conn(session) when is_pid(session) do
    id = ExWapp.Messages.generate_id()
    node = IQ.build_media_conn_query(id)

    case GenServer.call(session, {:send_iq, node, id}, 30_000) do
      {:ok, response} -> IQ.parse_media_conn_response(response)
      {:error, reason} -> {:error, reason}
      other -> {:error, {:bad_media_conn_response, other}}
    end
  end

  defp query_media_conn(_), do: {:error, :missing_session_for_media_conn}

  @spec do_upload(map(), Media.Upload.t(), binary()) ::
          {:ok, Media.Upload.t()} | {:error, term()}
  defp do_upload(%{hosts: [%{hostname: host} | _], auth: auth}, upload, body) do
    token = Base.url_encode64(upload.file_enc_sha256)
    mms_type = mms_type(upload.type)

    url = "https://#{host}/mms/#{mms_type}/#{token}?auth=#{uri(auth)}&token=#{uri(token)}"

    headers = [
      {~c"origin", String.to_charlist(@origin)},
      {~c"referer", String.to_charlist(@origin <> "/")},
      {~c"content-type", ~c"application/octet-stream"}
    ]

    request = {String.to_charlist(url), headers, ~c"application/octet-stream", body}

    case :httpc.request(:post, request, TLS.httpc_options(url), body_format: :binary) do
      {:ok, {{_, status, _}, _headers, response_body}} when status in 200..299 ->
        {:ok, struct(upload, parse_upload_response(response_body))}

      {:ok, {{_, status, _}, _headers, response_body}} ->
        {:error, {:upload_http_error, status, byte_size(response_body)}}

      {:error, reason} ->
        {:error, {:upload_failed, reason}}
    end
  end

  defp do_upload(_media_conn, _upload, _body), do: {:error, :missing_media_host}

  @spec do_download(map(), Media.Ref.t(), keyword()) :: {:ok, binary()} | {:error, term()}
  defp do_download(%{hosts: hosts}, %Media.Ref{url: url} = ref, opts)
       when is_binary(url) and url != "" do
    try_download_urls([url], hosts, ref, opts)
  end

  defp do_download(%{hosts: hosts}, %Media.Ref{direct_path: direct_path} = ref, opts)
       when is_binary(direct_path) and direct_path != "" do
    hash = Base.url_encode64(ref.file_enc_sha256 || <<>>)
    mms_type = mms_type(ref.type)

    # When the full CDN URL is missing, we reconstruct candidates from `media_conn`
    # hosts plus the server-provided direct path.
    urls =
      Enum.map(hosts, fn %{hostname: host} ->
        "https://#{host}#{direct_path}&hash=#{hash}&mms-type=#{mms_type}&__wa-mms="
      end)

    try_download_urls(urls, hosts, ref, opts)
  end

  defp do_download(_media_conn, _ref, _opts), do: {:error, :missing_media_url}

  @spec try_download_urls([binary()], list(), Media.Ref.t(), keyword()) ::
          {:ok, binary()} | {:error, term()}
  defp try_download_urls([], _hosts, _ref, _opts), do: {:error, :media_download_failed}

  defp try_download_urls([url | rest], hosts, ref, opts) do
    case http_get(url) do
      {:ok, body} -> {:ok, body}
      {:error, _reason} when rest != [] -> try_download_urls(rest, hosts, ref, opts)
      {:error, reason} -> {:error, reason}
    end
  end

  @spec http_get(binary()) :: {:ok, binary()} | {:error, term()}
  defp http_get(url) do
    headers = [
      {~c"origin", String.to_charlist(@origin)},
      {~c"referer", String.to_charlist(@origin <> "/")}
    ]

    case :httpc.request(:get, {String.to_charlist(url), headers}, TLS.httpc_options(url),
           body_format: :binary
         ) do
      {:ok, {{_, status, _}, _headers, body}} when status in 200..299 ->
        {:ok, body}

      {:ok, {{_, status, _}, _headers, body}} ->
        {:error, {:download_http_error, status, byte_size(body)}}

      {:error, reason} ->
        {:error, {:download_failed, reason}}
    end
  end

  @spec parse_upload_response(binary()) :: map()
  defp parse_upload_response(body) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, json} ->
        %{
          url: Map.get(json, "url"),
          direct_path: Map.get(json, "direct_path"),
          handle: Map.get(json, "handle"),
          object_id: Map.get(json, "object_id")
        }

      _ ->
        %{}
    end
  rescue
    UndefinedFunctionError -> parse_upload_response_without_json(body)
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

  @spec mms_type(Media.media_type()) :: binary()
  defp mms_type(:image), do: "image"
  defp mms_type(:audio), do: "audio"
  defp mms_type(:document), do: "document"

  @spec uri(term()) :: binary()
  defp uri(value), do: value |> to_string() |> URI.encode_www_form()
end
