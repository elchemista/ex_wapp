defmodule ExWapp.JSONTest do
  use ExUnit.Case, async: false

  defmodule DelegatingLibrary do
    @behaviour ExWapp.JSON.Library

    @impl true
    def encode(value), do: {:ok, JSON.encode!(value)}

    @impl true
    def decode(value), do: JSON.decode(value)
  end

  defmodule InvalidResponseLibrary do
    def encode(_value), do: :invalid_encode_result
    def decode(_value), do: :invalid_decode_result
  end

  defmodule RaisingLibrary do
    def encode(_value), do: raise("encoder failed")
    def decode(_value), do: raise("decoder failed")
  end

  defmodule ErrorLibrary do
    def encode(_value), do: {:error, :cannot_encode}
    def decode(_value), do: {:error, :cannot_decode}
  end

  defmodule InvalidIodataLibrary do
    def encode(_value), do: {:ok, %{not: :iodata}}
    def decode(_value), do: {:ok, :decoded}
  end

  setup do
    previous = Application.get_env(:ex_wapp, :json_library)

    on_exit(fn ->
      if previous do
        Application.put_env(:ex_wapp, :json_library, previous)
      else
        Application.delete_env(:ex_wapp, :json_library)
      end
    end)

    :ok
  end

  test "uses the JSON module selected by the host application" do
    Application.put_env(:ex_wapp, :json_library, DelegatingLibrary)

    assert {:ok, encoded} = ExWapp.JSON.encode(%{"answer" => 42})
    assert {:ok, %{"answer" => 42}} = ExWapp.JSON.decode(encoded)
  end

  test "supports an implementation whose encoder exposes only a bang function" do
    Application.put_env(:ex_wapp, :json_library, JSON)

    assert %{"answer" => 42} =
             %{"answer" => 42}
             |> ExWapp.JSON.encode!()
             |> ExWapp.JSON.decode!()
  end

  test "reports a missing JSON configuration clearly" do
    Application.delete_env(:ex_wapp, :json_library)

    assert {:error, :json_library_not_configured} = ExWapp.JSON.encode(%{})

    assert_raise ArgumentError, ~r/config :ex_wapp, :json_library/, fn ->
      ExWapp.JSON.encode!(%{})
    end

    assert {:error, :json_library_not_configured} = ExWapp.JSON.decode("{}")

    assert_raise ArgumentError, ~r/JSON decode failed/, fn ->
      ExWapp.JSON.decode!("{}")
    end
  end

  test "rejects invalid library configuration" do
    Application.put_env(:ex_wapp, :json_library, "not a module")

    assert {:error, {:invalid_json_library, "not a module"}} = ExWapp.JSON.library()
    assert {:error, {:invalid_json_library, "not a module"}} = ExWapp.JSON.encode(%{})

    Application.put_env(:ex_wapp, :json_library, __MODULE__.MissingLibrary)

    assert {:error, {:invalid_json_library, __MODULE__.MissingLibrary}} =
             ExWapp.JSON.decode("{}")
  end

  test "rejects non-conventional library return values" do
    Application.put_env(:ex_wapp, :json_library, InvalidResponseLibrary)

    assert {:error, {:invalid_json_library_response, :encode, :invalid_encode_result}} =
             ExWapp.JSON.encode(%{})

    assert {:error, {:invalid_json_library_response, :decode, :invalid_decode_result}} =
             ExWapp.JSON.decode("{}")
  end

  test "propagates library errors and converts raised exceptions to errors" do
    Application.put_env(:ex_wapp, :json_library, ErrorLibrary)

    assert {:error, :cannot_encode} = ExWapp.JSON.encode(%{})
    assert {:error, :cannot_decode} = ExWapp.JSON.decode("{}")

    Application.put_env(:ex_wapp, :json_library, RaisingLibrary)

    assert {:error, %RuntimeError{message: "encoder failed"}} = ExWapp.JSON.encode(%{})
    assert {:error, %RuntimeError{message: "decoder failed"}} = ExWapp.JSON.decode("{}")
  end

  test "rejects an encoder success value that is not iodata" do
    Application.put_env(:ex_wapp, :json_library, InvalidIodataLibrary)

    assert {:error, {:invalid_json_library_response, :encode, {:ok, %{not: :iodata}}}} =
             ExWapp.JSON.encode(%{})
  end
end
