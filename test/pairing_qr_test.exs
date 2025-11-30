defmodule ExWapp.PairingQRTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ExWapp.{Pairing, Store}

  describe "qr_from_ref/2" do
    test "builds a versioned QR payload and persists generated secrets" do
      store = store_fixture()

      noise_public = :crypto.strong_rand_bytes(32)
      :ok = Store.persist(store, %{noise: %{static_public: noise_public}})

      pairing = Pairing.new(store)

      ref = "dummy-ref"
      qr = Pairing.qr_from_ref(pairing, ref)

      [prefixed_ref, noise_b64, identity_b64, adv_b64] = String.split(qr, ",")

      assert prefixed_ref == "2@" <> ref
      assert Base.decode64!(noise_b64) == noise_public

      decoded_identity = Base.decode64!(identity_b64)
      decoded_adv_secret = Base.decode64!(adv_b64)

      assert byte_size(decoded_identity) == 32
      assert byte_size(decoded_adv_secret) == 32

      {:ok, persisted} = Store.load(store)

      assert get_in(persisted, [:identity, :public]) == decoded_identity
      assert get_in(persisted, [:identity, :private]) |> byte_size() == 32
      assert persisted[:adv_secret] == decoded_adv_secret
    end
  end

  defp store_fixture do
    tmp_dir = Path.join(System.tmp_dir!(), "ex_wapp_pairing_qr_test")
    :ok = File.mkdir_p(tmp_dir)
    path = Path.join(tmp_dir, "store_#{System.unique_integer([:positive])}.etf")

    store = Store.Ets.new(path: path)

    on_exit(fn -> File.rm(path) end)

    store
  end
end
