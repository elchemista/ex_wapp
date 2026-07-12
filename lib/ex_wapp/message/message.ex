defmodule ExWapp.Message do
  @moduledoc """
  User-facing WhatsApp message struct.

  This is the high-level value applications pass to ExWapp, similar to how an
  email library exposes a mail struct instead of making users call MIME builders
  directly.
  """

  defstruct [:id, :to, :type, :body, opts: [], metadata: %{}]

  alias ExWapp.Media

  @typedoc """
  High-level message categories supported by the public API.
  """
  @type message_type ::
          :text
          | :typing
          | :read_receipt
          | :image
          | :audio
          | :document
          | :location
          | :contact
          | :event
          | atom()

  @typedoc """
  Runtime-neutral message value passed into transport adapters.
  """
  @type t :: %__MODULE__{
          id: String.t() | nil,
          to: String.t(),
          type: message_type(),
          body: term(),
          opts: keyword(),
          metadata: map()
        }

  @doc """
  Builds a plain text message.

  This is the simplest outbound message form and maps to WhatsApp's
  `conversation` or `extendedTextMessage` protobuf fields depending on options.
  """
  @spec text(String.t(), iodata(), keyword()) :: t()
  def text(to, body, opts \\ []) when is_binary(to) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :text,
      body: IO.iodata_to_binary(body),
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds a typing indicator message.

  The boolean body is interpreted as `true => composing` and `false => paused`.
  """
  @spec typing(String.t(), boolean(), keyword()) :: t()
  def typing(to, composing \\ true, opts \\ []) when is_binary(to) and is_boolean(composing) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :typing,
      body: composing,
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds a read receipt message for one or more message IDs.
  """
  @spec read_receipt(String.t(), [String.t()], keyword()) :: t()
  def read_receipt(to, message_ids, opts \\ []) when is_binary(to) and is_list(message_ids) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :read_receipt,
      body: message_ids,
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds an image message from bytes, a filesystem path, or a pre-uploaded reference.
  """
  @spec image(String.t(), Media.source(), keyword()) :: t()
  def image(to, source, opts \\ []) when is_binary(to) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :image,
      body: source,
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds an audio message from bytes, a filesystem path, or a pre-uploaded reference.
  """
  @spec audio(String.t(), Media.source(), keyword()) :: t()
  def audio(to, source, opts \\ []) when is_binary(to) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :audio,
      body: source,
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds a document message from bytes, a filesystem path, or a pre-uploaded reference.
  """
  @spec document(String.t(), Media.source(), keyword()) :: t()
  def document(to, source, opts \\ []) when is_binary(to) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :document,
      body: source,
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds a static GPS location message.

  Latitude and longitude are encoded as protobuf doubles. Optional fields such
  as `:name`, `:address`, `:url`, `:comment`, and `:accuracy` are kept in
  `opts` until the session transport builds the wire payload.
  """
  @spec location(String.t(), number(), number(), keyword()) :: t()
  def location(to, latitude, longitude, opts \\ [])
      when is_binary(to) and is_number(latitude) and is_number(longitude) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :location,
      body: %{latitude: latitude, longitude: longitude},
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds a single WhatsApp contact card message.

  `vcard` must contain the complete vCard payload (normally vCard 3.0).
  """
  @spec contact(String.t(), String.t(), String.t(), keyword()) :: t()
  def contact(to, display_name, vcard, opts \\ [])
      when is_binary(to) and is_binary(display_name) and is_binary(vcard) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :contact,
      body: %{display_name: display_name, vcard: vcard},
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end

  @doc """
  Builds a WhatsApp calendar event message.

  This message type exists in WhatsApp Web but is less stable than text,
  media, location, and contact messages. `start_time` may be a Unix timestamp
  in seconds or a `DateTime`.
  """
  @spec event(String.t(), String.t(), integer() | DateTime.t(), keyword()) :: t()
  def event(to, name, start_time, opts \\ [])
      when is_binary(to) and is_binary(name) and
             (is_integer(start_time) or is_struct(start_time, DateTime)) do
    %__MODULE__{
      id: Keyword.get(opts, :id),
      to: to,
      type: :event,
      body: %{name: name, start_time: start_time},
      opts: Keyword.drop(opts, [:id, :metadata]),
      metadata: Keyword.get(opts, :metadata, %{})
    }
  end
end
