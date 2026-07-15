defmodule ExWapp.Session.AppStateSyncTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.AppStateSync
  alias ExWapp.Store.Memory

  test "schedules initial collections only when keys are available" do
    store =
      Memory.new(
        initial_data: %{
          app_state_keys: %{"key-id" => %{data: :binary.copy(<<1>>, 32), timestamp: 1}}
        }
      )

    state = %{runtime_cfg: %{}, session_id: "schedule-sync", store: store}

    assert AppStateSync.keys_available?(store)
    assert AppStateSync.schedule_initial(state, self()) == state

    assert_receive {:app_state_initial_sync, collections}
    assert is_list(collections)
    assert collections != []
  end

  test "runtime opt-out suppresses initial scheduling" do
    store =
      Memory.new(
        initial_data: %{
          app_state_keys: %{"key-id" => %{data: :binary.copy(<<2>>, 32), timestamp: 1}}
        }
      )

    state = %{
      runtime_cfg: %{app_state: %{initial_sync_enabled: false}},
      session_id: "disabled-sync",
      store: store
    }

    refute AppStateSync.initial_enabled?(state)
    assert AppStateSync.schedule_initial(state, self()) == state
    refute_receive {:app_state_initial_sync, _collections}
  end

  test "reports an unavailable task supervisor without starting a refresh" do
    assert {:error, :task_supervisor_unavailable} =
             AppStateSync.refresh(nil, self(), Memory.new(), ["regular_high"], :initial)

    refute_receive {:initial_sync_finished, _, _}
  end
end
