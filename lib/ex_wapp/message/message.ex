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
  @type message_type :: :text | :typing | :read_receipt | :image | :audio | atom()

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
end
