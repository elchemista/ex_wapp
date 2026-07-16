defmodule ExWapp.Transport.TLS do
  @moduledoc false

  @spec websockex_options(String.t()) :: keyword()
  def websockex_options(url) when is_binary(url) do
    case ssl_options(url) do
      [] ->
        []

      ssl_options ->
        # WebSockex defaults to no peer verification. Supplying explicit SSL
        # options also adds the hostname verification omitted by its shortcut.
        [
          insecure: false,
          cacerts: Keyword.fetch!(ssl_options, :cacerts),
          ssl_options: ssl_options
        ]
    end
  end

  @spec httpc_options(String.t(), keyword()) :: keyword()
  def httpc_options(url, options \\ []) when is_binary(url) and is_list(options) do
    case ssl_options(url) do
      [] -> options
      ssl_options -> Keyword.put(options, :ssl, Keyword.put(ssl_options, :log_level, :none))
    end
  end

  @spec ssl_options(String.t()) :: keyword()
  def ssl_options(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host}
      when scheme in ["wss", "https"] and is_binary(host) and host != "" ->
        [
          verify: :verify_peer,
          cacerts: :public_key.cacerts_get(),
          server_name_indication: String.to_charlist(host),
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]

      _other ->
        []
    end
  end
end
