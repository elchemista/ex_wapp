defmodule ExWapp.Message.Content do
  @moduledoc """
  Canonical content contract for inbound WhatsApp messages.

  The struct is intentionally independent from transport and Signal details.
  Legacy message-map fields remain available at the publishing boundary while
  wrappers can consume this single typed value.
  """

  alias ExWapp.Media.Ref

  @type kind :: :text | :media | :location | :contact | :event | :protocol | :unsupported

  @enforce_keys [:kind]
  defstruct [
    :kind,
    :text,
    :media,
    :media_type,
    :location,
    :contact,
    :event,
    :protocol_payload,
    diagnostics: %{}
  ]

  @type t :: %__MODULE__{
          kind: kind(),
          text: binary() | nil,
          media: Ref.t() | nil,
          media_type: atom() | nil,
          location: map() | nil,
          contact: map() | nil,
          event: map() | nil,
          protocol_payload: binary() | nil,
          diagnostics: map()
        }

  @doc """
  Builds a canonical content value from one supported kind and its fields.
  """
  @spec new(kind(), keyword()) :: t()
  def new(kind, attrs \\ [])
      when kind in [:text, :media, :location, :contact, :event, :protocol, :unsupported] and
             is_list(attrs) do
    struct!(__MODULE__, Keyword.put(attrs, :kind, kind))
  end

  @doc """
  Adapts an already-normalized legacy message map to the canonical contract.
  """
  @spec from_legacy(map()) :: t()
  def from_legacy(%{content: %__MODULE__{} = content}), do: content

  def from_legacy(message_data) when is_map(message_data) do
    cond do
      Map.get(message_data, :message_content_type) == :protocol ->
        new(:protocol,
          text: Map.get(message_data, :text),
          protocol_payload: Map.get(message_data, :protocol_payload),
          diagnostics: legacy_diagnostics(message_data)
        )

      match?({:error, _}, Map.get(message_data, :decrypt_status)) or
          Map.get(message_data, :placeholder_unavailable) == true ->
        new(:unsupported,
          text: Map.get(message_data, :text),
          diagnostics: legacy_diagnostics(message_data)
        )

      match?(%Ref{}, Map.get(message_data, :media)) ->
        media = Map.fetch!(message_data, :media)

        new(:media,
          text: Map.get(message_data, :text),
          media: media,
          media_type: Map.get(message_data, :media_type) || media.type,
          diagnostics: legacy_diagnostics(message_data)
        )

      is_map(Map.get(message_data, :location)) ->
        new(:location,
          text: Map.get(message_data, :text),
          location: Map.get(message_data, :location),
          diagnostics: legacy_diagnostics(message_data)
        )

      is_map(Map.get(message_data, :contact)) ->
        new(:contact,
          text: Map.get(message_data, :text),
          contact: Map.get(message_data, :contact),
          diagnostics: legacy_diagnostics(message_data)
        )

      is_map(Map.get(message_data, :event)) ->
        new(:event,
          text: Map.get(message_data, :text),
          event: Map.get(message_data, :event),
          diagnostics: legacy_diagnostics(message_data)
        )

      is_binary(Map.get(message_data, :text)) ->
        new(:text,
          text: Map.get(message_data, :text),
          diagnostics: legacy_diagnostics(message_data)
        )

      true ->
        new(:unsupported, diagnostics: legacy_diagnostics(message_data))
    end
  end

  @doc """
  Converts canonical content to the existing message-map fields.
  """
  @spec to_legacy(t()) :: map()
  def to_legacy(%__MODULE__{kind: :text} = content) do
    %{text: content.text, message_content_type: :user_message}
  end

  def to_legacy(%__MODULE__{kind: :media} = content) do
    %{
      text: content.text,
      media: content.media,
      media_type: content.media_type,
      content_type: content.media_type,
      message_content_type: :user_message
    }
  end

  def to_legacy(%__MODULE__{kind: :location} = content) do
    %{
      text: content.text,
      location: content.location,
      content_type: :location,
      message_content_type: :user_message
    }
  end

  def to_legacy(%__MODULE__{kind: :contact} = content) do
    %{
      text: content.text,
      contact: content.contact,
      content_type: :contact,
      message_content_type: :user_message
    }
  end

  def to_legacy(%__MODULE__{kind: :event} = content) do
    %{
      text: content.text,
      event: content.event,
      content_type: :event,
      message_content_type: :user_message
    }
  end

  def to_legacy(%__MODULE__{kind: :protocol} = content) do
    %{
      text: content.text,
      message_content_type: :protocol,
      protocol_payload: content.protocol_payload
    }
  end

  def to_legacy(%__MODULE__{kind: :unsupported} = content) do
    %{
      text: content.text,
      message_content_type: :unsupported,
      unsupported_content: content.diagnostics
    }
  end

  @spec legacy_diagnostics(map()) :: map()
  defp legacy_diagnostics(message_data) do
    %{
      decrypt_status: Map.get(message_data, :decrypt_status),
      encrypted: Map.get(message_data, :encrypted, false),
      enc_type: Map.get(message_data, :enc_type),
      placeholder_unavailable: Map.get(message_data, :placeholder_unavailable, false)
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) or value == false end)
    |> Map.new()
  end
end
