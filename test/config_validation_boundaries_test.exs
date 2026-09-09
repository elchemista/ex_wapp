defmodule ExWapp.ConfigValidationBoundariesTest do
  use ExUnit.Case, async: true
  alias ExWapp.Config
  alias ExWapp.Config.Validator

  test "invalid scalar runtime options identify the exact setting before a session starts" do
    defaults = Config.defaults()

    for {path, value, expected} <- [
          {[:quota, :reset_timezone], 1, :expected_binary},
          {[:release_gates, :feature_flags], [], :expected_map},
          {[:throttle, :enabled], :yes, :expected_boolean},
          {[:send, :max_outgoing_retry_attempts], -1, :expected_non_neg_integer},
          {[:throttle, :global, :messages_per_second], 0, :expected_positive_number},
          {[:prekeys, :id_allocator], fn _ -> :ok end, {:expected_function, 2}},
          {[:protocol, :pairing_device_props, :history_sync_config, :storage_quota_mb], -1,
           :expected_non_neg_integer},
          {[:protocol, :pairing_device_props, :require_full_sync], :yes, :expected_boolean}
        ] do
      invalid = put_in(defaults, path, value)

      assert {:error, {:invalid_runtime_config, ^path, ^value, ^expected}} =
               Validator.validate(invalid)
    end

    assert :ok = Validator.validate(defaults)
    assert {:error, {:invalid_runtime_config, :not_a_map}} = Validator.validate([])

    assert :ok =
             Validator.validate(
               put_in(defaults, [:prekeys, :id_allocator], fn floor, _count -> {:ok, floor} end)
             )

    assert :ok =
             Validator.validate(put_in(defaults, [:throttle, :global, :messages_per_second], 2))
  end

  test "retry schedules and feature lists reject wrong containers and element types" do
    for {path, value, expected} <- [
          {[:send, :retry_backoff_ms], [0], :expected_list_of_positive_integers},
          {[:send, :session_repair_backoff_ms], [-1], :expected_list_of_non_neg_integers},
          {[:canary, :recipients], [:alice], :expected_list_of_binaries},
          {[:enforcement, :snapshot_on_signals], ["failure"], :expected_list_of_atoms},
          {[:release_gates, :blocked_features], [1], :expected_list_of_atoms_or_binaries}
        ] do
      assert {:error, {:invalid_runtime_config, ^path, ^value, ^expected}} =
               Validator.validate(put_in(Config.defaults(), path, value))

      assert {:error, {:invalid_runtime_config, ^path, :invalid, :expected_list}} =
               Validator.validate(put_in(Config.defaults(), path, :invalid))
    end
  end
end
