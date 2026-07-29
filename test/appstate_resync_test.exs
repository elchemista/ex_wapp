defmodule ExWapp.AppStateResyncTest do
  @moduledoc """
  Coverage for recovery from a diverged app-state hash chain.

  Once the local LTHash disagrees with the server's chain, no ordinary retry
  can repair it: a snapshot is only requested at version 0, so every fetch
  runs with the stored version, gets the same failing patch back, and errors
  again — and because every outgoing mutation fetches the collection first,
  archive/pin/mute for that collection fail forever. The engine has to drop
  the stored version and start over from a snapshot, which is what whatsmeow
  does for this class of error.
  """

  use ExUnit.Case, async: true

  import Bitwise

  alias ExWapp.AppState.Engine
  alias ExWapp.Binary.Node
  alias ExWapp.Store

  @collection "regular_low"

  defmodule FakeSession do
    @moduledoc false
    use GenServer

    def start_link(responses), do: GenServer.start_link(__MODULE__, responses)
    def requests(pid), do: GenServer.call(pid, :requests)

    @impl true
    def init(responses), do: {:ok, %{responses: responses, requests: []}}

    @impl true
    def handle_call({:send_iq, iq_node, _message_id}, _from, state) do
      [next | rest] = state.responses
      {:reply, {:ok, next}, %{state | responses: rest, requests: [iq_node | state.requests]}}
    end

    def handle_call(:requests, _from, state), do: {:reply, Enum.reverse(state.requests), state}
  end

  test "a diverged patch chain drops the stored version and resyncs from a snapshot" do
    key_id = :crypto.strong_rand_bytes(16)
    key_data = :crypto.strong_rand_bytes(32)
    key_hex = Base.encode16(key_id, case: :lower)

    store = Store.new(Store.Memory)

    :ok =
      Store.transaction(store, fn data ->
        Map.put(data, :app_state_keys, %{key_hex => %{data: key_data, timestamp: 1}})
      end)

    # A real two-patch chain, but the store keeps a corrupted copy of the state
    # after patch one — the local hash has silently diverged from the chain the
    # server is still serving.
    initial_state = %{version: 0, hash: ExWapp.AppState.LTHash.new()}

    {:ok, _first_binary, state_1, macs_1} =
      Engine.encode_patch(
        Engine.build_pin("15550001111@s.whatsapp.net", true),
        key_id,
        key_data,
        initial_state,
        %{}
      )

    {:ok, second_binary, _state_2, _macs_2} =
      Engine.encode_patch(
        Engine.build_pin("15550001111@s.whatsapp.net", false),
        key_id,
        key_data,
        state_1,
        macs_1
      )

    <<first_byte, hash_rest::binary>> = state_1.hash
    diverged = %{state_1 | hash: <<bxor(first_byte, 1), hash_rest::binary>>}
    :ok = Engine.persist_collection_state(store, @collection, diverged, macs_1)

    # First fetch: the server serves the genuine patch two, which cannot
    # validate against the diverged local hash. Second fetch (after the reset)
    # asks for a snapshot; an empty collection completes the sync.
    responses = [
      collection_response([patch_node(second_binary)]),
      collection_response([])
    ]

    {:ok, session} = FakeSession.start_link(responses)

    assert :ok = Engine.fetch_collection(session, store, @collection)

    assert [first_request, second_request] = FakeSession.requests(session)
    assert collection_attrs(first_request)["return_snapshot"] == "false"
    assert collection_attrs(first_request)["version"] == "1"
    assert collection_attrs(second_request)["return_snapshot"] == "true"

    # The diverged state is gone: the store is back at version 0 rather than
    # still pinned in front of a patch it can never validate.
    assert {:ok, %{version: 0}, %{}} = Engine.get_collection_state(store, @collection)
  end

  defp collection_response(children) do
    %Node{
      tag: "iq",
      attrs: %{"type" => "result"},
      content: [
        %Node{
          tag: "sync",
          attrs: %{},
          content: [
            %Node{
              tag: "collection",
              attrs: %{"name" => @collection, "has_more_patches" => "false"},
              content: children
            }
          ]
        }
      ]
    }
  end

  defp patch_node(patch_binary) do
    %Node{tag: "patches", attrs: %{}, content: [%Node{tag: "patch", content: patch_binary}]}
  end

  defp collection_attrs(%Node{} = iq_node) do
    iq_node
    |> find_node("collection")
    |> Map.fetch!(:attrs)
  end

  defp find_node(%Node{tag: tag} = node, tag), do: node

  defp find_node(%Node{content: children}, tag) when is_list(children),
    do: Enum.find_value(children, &find_node(&1, tag))

  defp find_node(_node, _tag), do: nil
end
