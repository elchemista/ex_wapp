defmodule ExWapp.JSON do
  @moduledoc """
  Configurable JSON boundary used by ExWapp.

  ExWapp deliberately does not depend on a JSON implementation. The host
  application must provide a module exposing `encode/1` and `decode/1` with
  the conventional `{:ok, value} | {:error, reason}` return shape:

      config :ex_wapp, :json_library, Jason

  Jason, Poison, Elixir's `JSON` module, or a small adapter around another
  implementation can be used. Modules exposing only the bang variants are
  supported too.
  """

  defmodule Library do
    @moduledoc """
    Contract expected from the configured JSON implementation.

    A library does not have to declare this behaviour explicitly. An adapter
    module is sufficient when its native API has a different return shape.
    """

    @type reason :: term()

    @callback encode(term()) :: {:ok, iodata()} | {:error, reason()}
    @callback decode(iodata()) :: {:ok, term()} | {:error, reason()}
  end

  @type error_reason ::
          :json_library_not_configured
          | {:invalid_json_library, term()}
          | {:invalid_json_library_response, :encode | :decode, term()}
          | term()

  @doc "Returns the JSON module configured by the host application."
  @spec library() :: {:ok, module()} | {:error, error_reason()}
  def library do
    case Application.fetch_env(:ex_wapp, :json_library) do
      {:ok, library} when is_atom(library) -> {:ok, library}
      {:ok, library} -> {:error, {:invalid_json_library, library}}
      :error -> {:error, :json_library_not_configured}
    end
  end

  @doc "Encodes a value with the configured JSON implementation."
  @spec encode(term()) :: {:ok, binary()} | {:error, error_reason()}
  def encode(value) do
    with {:ok, library} <- library(),
         {:ok, result} <- invoke(library, :encode, value) do
      normalize_encode_result(result)
    end
  rescue
    exception -> {:error, exception}
  end

  @doc "Encodes a value or raises when JSON is unavailable or encoding fails."
  @spec encode!(term()) :: binary() | no_return()
  def encode!(value) do
    case encode(value) do
      {:ok, encoded} -> encoded
      {:error, reason} -> raise ArgumentError, json_error(:encode, reason)
    end
  end

  @doc "Decodes JSON with the configured JSON implementation."
  @spec decode(iodata()) :: {:ok, term()} | {:error, error_reason()}
  def decode(value) do
    with {:ok, library} <- library(),
         {:ok, result} <- invoke(library, :decode, value) do
      normalize_decode_result(result)
    end
  rescue
    exception -> {:error, exception}
  end

  @doc "Decodes JSON or raises when JSON is unavailable or decoding fails."
  @spec decode!(iodata()) :: term() | no_return()
  def decode!(value) do
    case decode(value) do
      {:ok, decoded} -> decoded
      {:error, reason} -> raise ArgumentError, json_error(:decode, reason)
    end
  end

  defp invoke(library, function, value) do
    bang_function = bang_function(function)

    cond do
      not Code.ensure_loaded?(library) ->
        {:error, {:invalid_json_library, library}}

      function_exported?(library, function, 1) ->
        {:ok, apply(library, function, [value])}

      function_exported?(library, bang_function, 1) ->
        {:ok, {:ok, apply(library, bang_function, [value])}}

      true ->
        {:error, {:invalid_json_library, library}}
    end
  end

  defp bang_function(:encode), do: :encode!
  defp bang_function(:decode), do: :decode!

  defp normalize_encode_result({:ok, encoded}) do
    {:ok, IO.iodata_to_binary(encoded)}
  rescue
    _exception -> {:error, {:invalid_json_library_response, :encode, {:ok, encoded}}}
  end

  defp normalize_encode_result({:error, _reason} = error), do: error

  defp normalize_encode_result(other) do
    {:error, {:invalid_json_library_response, :encode, other}}
  end

  defp normalize_decode_result({:ok, _decoded} = result), do: result
  defp normalize_decode_result({:error, _reason} = error), do: error

  defp normalize_decode_result(other) do
    {:error, {:invalid_json_library_response, :decode, other}}
  end

  defp json_error(operation, reason) do
    "JSON #{operation} failed using config :ex_wapp, :json_library: #{inspect(reason)}"
  end
end
