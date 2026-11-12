defmodule ExWapp.MediaHTTPTest do
  use ExUnit.Case, async: true

  alias ExWapp.Binary.Node
  alias ExWapp.Media.{Crypto, HTTP, Ref}

  defmodule IQSession do
    use GenServer
    def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
    @impl true
    def init(opts), do: {:ok, opts}
    @impl true
    def handle_call({:send_iq, node, id, _timeout}, _from, {owner, reply} = state) do
      send(owner, {:media_iq, node, id})
      {:reply, reply, state}
    end
  end

  test "rejects sender-controlled HTTP URLs before connecting" do
    ref = %{reference(:image) | url: "http://127.0.0.1/private"}
    assert {:error, :untrusted_media_url} = HTTP.download(%{}, ref)
  end

  test "missing keys and oversized media are rejected before network access" do
    assert {:error, :invalid_media_key} =
             HTTP.download(%{}, %Ref{type: :image, url: "https://mmg.whatsapp.net/x"})

    ref = %{reference(:image) | file_length: 100}
    assert {:error, :media_too_large} = HTTP.download(%{}, ref, max_bytes: 10)
  end

  test "an untrusted URL can fall back only through supplied media connection hosts" do
    ref = %{reference(:image) | url: "http://127.0.0.1/private", direct_path: "/missing?x=1"}
    assert {:error, :media_download_failed} = HTTP.download(%{}, ref, media_conn: %{hosts: []})
  end

  test "missing connection data and missing paths return actionable errors" do
    ref = reference(:document)
    assert {:error, :missing_session_for_media_conn} = HTTP.download(%{}, ref)
    assert {:error, :missing_media_url} = HTTP.download(%{}, ref, media_conn: %{hosts: []})
    assert {:error, :missing_session_for_media_conn} = HTTP.upload(%{}, :image, "image")

    assert {:error, :missing_media_host} =
             HTTP.upload(%{}, :audio, "audio", media_conn: %{hosts: [], auth: "token"})
  end

  test "media connection IQ errors are propagated without an HTTP request" do
    session = start_supervised!({IQSession, {self(), {:error, :iq_timeout}}})
    assert {:error, :iq_timeout} = HTTP.upload(%{}, :document, "document", session: session)

    assert_receive {:media_iq,
                    %Node{tag: "iq", attrs: attrs, content: [%Node{tag: "media_conn"}]}, id}

    assert attrs["id"] == id
    assert attrs["xmlns"] == "w:m"
    assert attrs["type"] == "set"
  end

  test "unexpected media connection replies are classified" do
    session = start_supervised!({IQSession, {self(), :unexpected}})

    assert {:error, {:bad_media_conn_response, :unexpected}} =
             HTTP.download(%{}, reference(:image), session: session)
  end

  test "successful media connection replies still require an upload host" do
    response = %Node{
      tag: "iq",
      attrs: %{"type" => "result"},
      content: [%Node{tag: "media_conn", attrs: %{"auth" => "token"}, content: []}]
    }

    session = start_supervised!({IQSession, {self(), {:ok, response}}})
    assert {:error, :missing_media_host} = HTTP.upload(%{}, :image, "image", session: session)
  end

  defp reference(type) do
    {:ok, upload, _body} = Crypto.encrypt_upload("fixture", type)
    ExWapp.Media.ref_from_upload(upload)
  end
end
