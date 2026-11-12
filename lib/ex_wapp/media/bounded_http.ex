defmodule ExWapp.Media.BoundedHTTP do
  @moduledoc false
  alias ExWapp.Transport.TLS
  @header_limit 32_768

  @typep headers :: [{String.t(), String.t()}]
  @typep result :: {:ok, binary()} | {:error, term()}
  @typep socket :: :ssl.sslsocket()

  # One verified TLS connection per bounded request. Passive reads and a shared
  # absolute deadline bound successful bodies AND HTTP error bodies; redirects
  # are never followed. No connection is returned to a pool with unread bytes.
  @spec request(
          :get | :post,
          String.t(),
          [{String.t() | charlist(), String.t() | charlist()}],
          binary(),
          pos_integer(),
          integer()
        ) :: {:ok, non_neg_integer(), binary()} | {:error, term()}
  def request(method, url, headers, body, max_bytes, deadline) do
    uri = URI.parse(url)
    timeout = min(remaining(deadline), 10_000)

    options =
      TLS.ssl_options(url) ++
        [mode: :binary, active: false, packet: :http_bin, packet_size: @header_limit]

    with true <- timeout > 0,
         {:ok, socket} <-
           :ssl.connect(String.to_charlist(uri.host), uri.port || 443, options, timeout) do
      try do
        path = (uri.path || "/") <> if(uri.query, do: "?" <> uri.query, else: "")
        host = if String.contains?(uri.host, ":"), do: "[#{uri.host}]", else: uri.host
        authority = if uri.port in [nil, 443], do: host, else: "#{host}:#{uri.port}"

        request = [
          String.upcase(to_string(method)),
          " ",
          path,
          " HTTP/1.1\r\n",
          "Host: ",
          authority,
          "\r\nConnection: close\r\nAccept-Encoding: identity\r\n",
          Enum.map(headers, fn {key, value} -> [key, ": ", value, "\r\n"] end),
          if(method == :post,
            do: ["Content-Length: ", Integer.to_string(byte_size(body)), "\r\n"],
            else: []
          ),
          "\r\n",
          body
        ]

        with :ok <-
               :ssl.setopts(socket, send_timeout: remaining(deadline), send_timeout_close: true),
             :ok <- :ssl.send(socket, request),
             {:ok, status, response_headers} <- response_head(socket, deadline, 0),
             :ok <- accepted_status(status),
             {:ok, data} <- read_body(socket, response_headers, max_bytes, deadline) do
          {:ok, status, data}
        else
          {:error, _} = error -> error
        end
      after
        :ssl.close(socket)
      end
    else
      false -> {:error, :timeout}
      {:error, _} = error -> error
    end
  rescue
    _ -> {:error, :invalid_http_response}
  end

  @spec accepted_status(non_neg_integer()) :: :ok | {:error, {:http_status, non_neg_integer()}}
  defp accepted_status(status) when status in 200..299, do: :ok
  defp accepted_status(status), do: {:error, {:http_status, status}}

  @spec response_head(socket(), integer(), non_neg_integer()) ::
          {:ok, non_neg_integer(), headers()} | {:error, term()}
  defp response_head(_socket, _deadline, count) when count > 4,
    do: {:error, :too_many_interim_responses}

  defp response_head(socket, deadline, count) do
    with {:ok, {:http_response, _version, status, _reason}} <- recv(socket, 0, deadline),
         {:ok, headers} <- read_headers(socket, deadline, [], 0) do
      if status in 100..199,
        do: response_head(socket, deadline, count + 1),
        else: {:ok, status, headers}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_http_response}
    end
  end

  @spec read_headers(socket(), integer(), headers(), non_neg_integer()) ::
          {:ok, headers()} | {:error, term()}
  defp read_headers(socket, deadline, headers, size) do
    case recv(socket, 0, deadline) do
      {:ok, :http_eoh} ->
        {:ok, headers}

      {:ok, {:http_header, _index, name, _reserved, value}} ->
        name = name |> to_string() |> String.downcase()
        value = to_string(value)
        size = size + byte_size(name) + byte_size(value) + 4

        if size <= @header_limit,
          do: read_headers(socket, deadline, [{name, value} | headers], size),
          else: {:error, :headers_too_large}

      {:error, _} = error ->
        error

      _ ->
        {:error, :invalid_http_headers}
    end
  end

  @spec read_body(socket(), headers(), pos_integer(), integer()) :: result()
  defp read_body(socket, headers, max_bytes, deadline) do
    transfer = values(headers, "transfer-encoding")
    lengths = values(headers, "content-length")
    encoding = values(headers, "content-encoding")

    with true <- encoding in [[], ["identity"]],
         :ok <- :ssl.setopts(socket, packet: :raw) do
      read_response_body(socket, transfer, lengths, max_bytes, deadline)
    else
      false -> {:error, :unsupported_content_encoding}
      {:error, _} = error -> error
    end
  end

  @spec read_response_body(socket(), [String.t()], [String.t()], pos_integer(), integer()) ::
          result()
  defp read_response_body(socket, transfer, lengths, max_bytes, deadline) do
    cond do
      transfer == ["chunked"] -> read_chunks(socket, max_bytes, deadline, [], 0)
      transfer != [] -> {:error, :unsupported_transfer_encoding}
      lengths == [] -> read_until_closed(socket, max_bytes, deadline, [], 0)
      length(Enum.uniq(lengths)) != 1 -> {:error, :invalid_content_length}
      true -> read_sized_body(socket, hd(lengths), max_bytes, deadline)
    end
  end

  @spec read_sized_body(socket(), String.t(), pos_integer(), integer()) :: result()
  defp read_sized_body(socket, length, max_bytes, deadline) do
    case Integer.parse(length) do
      {size, ""} when size >= 0 and size <= max_bytes -> read_exact(socket, size, deadline)
      {size, ""} when size > max_bytes -> {:error, :media_too_large}
      _ -> {:error, :invalid_content_length}
    end
  end

  @spec read_chunks(socket(), pos_integer(), integer(), [binary()], non_neg_integer()) :: result()
  defp read_chunks(socket, limit, deadline, chunks, size) do
    with :ok <- :ssl.setopts(socket, packet: :line, packet_size: 8192),
         {:ok, line} <- recv(socket, 0, deadline),
         [hex | _] <- String.split(String.trim(line), ";", parts: 2),
         {length, ""} when length >= 0 <- Integer.parse(hex, 16) do
      read_chunk(socket, limit, deadline, chunks, size, length)
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_chunk}
    end
  end

  @spec read_chunk(
          socket(),
          pos_integer(),
          integer(),
          [binary()],
          non_neg_integer(),
          non_neg_integer()
        ) :: result()
  defp read_chunk(_socket, limit, _deadline, _chunks, size, length) when size + length > limit,
    do: {:error, :media_too_large}

  defp read_chunk(_socket, _limit, _deadline, chunks, _size, 0),
    do: {:ok, chunks |> Enum.reverse() |> IO.iodata_to_binary()}

  defp read_chunk(socket, limit, deadline, chunks, size, length) do
    with :ok <- :ssl.setopts(socket, packet: :raw),
         {:ok, chunk} <- read_exact(socket, length, deadline),
         {:ok, "\r\n"} <- read_exact(socket, 2, deadline) do
      read_chunks(socket, limit, deadline, [chunk | chunks], size + length)
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_chunk}
    end
  end

  @spec read_until_closed(socket(), pos_integer(), integer(), [binary()], non_neg_integer()) ::
          result()
  defp read_until_closed(socket, limit, deadline, chunks, size) do
    case recv(socket, 0, deadline) do
      {:ok, chunk} when byte_size(chunk) + size <= limit ->
        read_until_closed(socket, limit, deadline, [chunk | chunks], size + byte_size(chunk))

      {:ok, _chunk} ->
        {:error, :media_too_large}

      {:error, :closed} ->
        {:ok, chunks |> Enum.reverse() |> IO.iodata_to_binary()}

      {:error, _} = error ->
        error
    end
  end

  @spec read_exact(socket(), non_neg_integer(), integer()) :: result()
  defp read_exact(_socket, 0, _deadline), do: {:ok, <<>>}
  defp read_exact(socket, size, deadline), do: recv(socket, size, deadline)

  @spec recv(socket(), non_neg_integer(), integer()) :: {:ok, term()} | {:error, term()}
  defp recv(socket, size, deadline) do
    case remaining(deadline) do
      0 -> {:error, :timeout}
      timeout -> :ssl.recv(socket, size, timeout)
    end
  end

  @spec values(headers(), String.t()) :: [String.t()]
  defp values(headers, key),
    do: for({^key, value} <- headers, do: String.downcase(String.trim(value)))

  @spec remaining(integer()) :: non_neg_integer()
  defp remaining(deadline), do: max(deadline - System.monotonic_time(:millisecond), 0)
end
