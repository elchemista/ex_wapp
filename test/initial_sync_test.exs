defmodule ExWapp.Session.InitialSyncTest do
  use ExUnit.Case, async: true

  alias ExWapp.Session.InitialSync

  test "tracks one task and resets task plus monitor atomically" do
    task = self()
    monitor = make_ref()

    sync = InitialSync.new()
    refute InitialSync.active?(sync)

    tracked = InitialSync.track(sync, task, monitor)
    assert InitialSync.active?(tracked)
    assert tracked.task == task
    assert tracked.monitor == monitor

    assert %InitialSync{task: nil, monitor: nil} = InitialSync.reset(tracked)
  end
end
