defmodule ExWapp.AppState.Engine.State do
  @moduledoc """
  Persistence helpers for app-state hash-chain metadata.

  The app-state protocol tracks a per-collection LTHash version and a mutation
  MAC cache. This module keeps those storage concerns separate from transport
  and decoding logic.
  """

  alias ExWapp.AppState.LTHash
  alias ExWapp.Store

  @all_collections [
    "critical_block",
    "critical_unblock_low",
    "regular_high",
    "regular_low",
    "regular"
  ]

  @type hash_state :: %{version: non_neg_integer(), hash: binary()}

  @doc """
  Returns the collection names tracked by the app-state engine.
  """
  @spec all_collections() :: [String.t()]
  def all_collections, do: @all_collections

  @doc """
  Loads the saved hash state and mutation MACs for one collection.
  """
  @spec get_collection_state(struct(), String.t()) :: {:ok, hash_state(), map()}
  def get_collection_state(store, collection_name) do
    data = Store.load!(store)
    versions = Map.get(data, :app_state_versions, %{})
    all_macs = Map.get(data, :app_state_mutation_macs, %{})

    collection_state = Map.get(versions, collection_name, %{version: 0, hash: LTHash.new()})
    collection_macs = Map.get(all_macs, collection_name, %{})

    {:ok, collection_state, collection_macs}
  end

  @doc """
  Persists the current hash state and mutation MACs for one collection.
  """
  @spec persist_collection_state(struct(), String.t(), hash_state(), map()) :: :ok
  def persist_collection_state(store, collection_name, hash_state, mutation_macs) do
    data = Store.load!(store)
    versions = Map.get(data, :app_state_versions, %{})
    all_macs = Map.get(data, :app_state_mutation_macs, %{})

    updated_versions = Map.put(versions, collection_name, hash_state)
    updated_macs = Map.put(all_macs, collection_name, mutation_macs)

    data =
      data
      |> Map.put(:app_state_versions, updated_versions)
      |> Map.put(:app_state_mutation_macs, updated_macs)

    Store.persist(store, data)
  end
end
