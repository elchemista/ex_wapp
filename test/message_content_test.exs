defmodule ExWapp.Message.ContentTest do
  use ExUnit.Case, async: true

  alias ExWapp.Media.Ref
  alias ExWapp.Message.Content

  test "adapts a decoded media map to the canonical contract" do
    media = %Ref{type: :image, direct_path: "/media/image", metadata: %{}}

    canonical =
      Content.from_legacy(%{
        text: "caption",
        media: media,
        media_type: :image,
        content_type: :image
      })

    assert canonical.kind == :media
    assert canonical.media == media
    assert canonical.media_type == :image
    assert canonical.text == "caption"

    assert %{
             text: "caption",
             media: ^media,
             media_type: :image,
             content_type: :image,
             message_content_type: :user_message
           } = Content.to_legacy(canonical)
  end

  test "keeps failed encrypted content explicit instead of treating it as text" do
    canonical =
      Content.from_legacy(%{
        encrypted: true,
        enc_type: "msg",
        text: "(encrypted: msg)",
        decrypt_status: {:error, :no_session}
      })

    assert canonical.kind == :unsupported
    assert canonical.text == "(encrypted: msg)"
    assert canonical.diagnostics.decrypt_status == {:error, :no_session}
    assert canonical.diagnostics.enc_type == "msg"

    assert %{message_content_type: :unsupported, unsupported_content: diagnostics} =
             Content.to_legacy(canonical)

    assert diagnostics.encrypted
  end
end
