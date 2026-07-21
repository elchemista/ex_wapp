defmodule ExWapp.AppState.CollectionLock do
  @moduledoc false

  alias ExWapp.Signal.MutationLock

  @doc "Runs an app-state operation exclusively for one store collection."
  @spec with_lock(struct(), String.t(), (-> result)) :: result when result: term()
  def with_lock(store, collection_name, fun)
      when is_struct(store) and is_binary(collection_name) and is_function(fun, 0) do
    MutationLock.with_lock({:app_state_collection, store, collection_name}, fun)
  end
end
