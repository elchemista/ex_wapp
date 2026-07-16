defmodule ExWapp.Session.Options do
  @moduledoc false

  alias ExWapp.{Client, Config}

  @enforce_keys [:runtime]
  defstruct session_id: nil,
            store: nil,
            transport: ExWapp.Conn,
            runtime: %{},
            auto_connect: false,
            reconnect: true,
            noise: [],
            name: nil

  @type t :: %__MODULE__{
          session_id: term() | nil,
          store: term(),
          transport: module(),
          runtime: map(),
          auto_connect: boolean(),
          reconnect: boolean(),
          noise: keyword(),
          name: GenServer.name() | nil
        }

  @spec from_start_options(keyword() | t()) :: {:ok, t()} | {:error, term()}
  def from_start_options(%__MODULE__{} = options), do: {:ok, options}

  def from_start_options(options) when is_list(options) do
    with {:ok, runtime} <- Config.resolve(options) do
      {:ok,
       %__MODULE__{
         session_id: Keyword.get(options, :session_id),
         store: Keyword.get(options, :store),
         transport: Keyword.get(options, :transport, ExWapp.Conn),
         runtime: runtime,
         auto_connect: Keyword.get(options, :auto_connect, false),
         reconnect: Keyword.get(options, :reconnect, true),
         noise: Keyword.get(options, :noise, []),
         name: Keyword.get(options, :name)
       }}
    end
  end

  def from_start_options(_options),
    do: {:error, {:invalid_session_options, :expected_keyword_or_options}}

  @spec from_client(Client.t(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_client(%Client{} = client, legacy_options \\ []) when is_list(legacy_options) do
    legacy_runtime = legacy_options |> Keyword.get(:runtime, %{}) |> normalize_container()
    runtime = deep_merge(client.runtime || %{}, legacy_runtime)

    legacy_options
    |> Keyword.put(:session_id, client.session_id)
    |> Keyword.put(:store, client.store)
    |> Keyword.put(:runtime, runtime)
    |> from_start_options()
  end

  @spec with_session_id(t() | keyword(), term()) :: {:ok, t()} | {:error, term()}
  def with_session_id(options, session_id) do
    with {:ok, options} <- from_start_options(options) do
      {:ok, %{options | session_id: session_id}}
    end
  end

  @spec gen_server_options(t() | keyword()) :: keyword()
  def gen_server_options(%__MODULE__{name: nil}), do: []
  def gen_server_options(%__MODULE__{name: name}), do: [name: name]
  def gen_server_options(options) when is_list(options), do: Keyword.take(options, [:name])

  defp deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn _key, left_value, right_value ->
      deep_merge(left_value, right_value)
    end)
  end

  defp deep_merge(_left, right), do: right

  defp normalize_container([]), do: []

  defp normalize_container(container) when is_list(container) do
    if Keyword.keyword?(container) do
      Map.new(container, fn {key, value} -> {key, normalize_container(value)} end)
    else
      container
    end
  end

  defp normalize_container(container) when is_map(container) do
    Map.new(container, fn {key, value} -> {key, normalize_container(value)} end)
  end

  defp normalize_container(value), do: value
end
