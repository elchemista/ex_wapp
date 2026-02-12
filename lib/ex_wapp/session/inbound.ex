defmodule ExWapp.Session.Inbound do
  @moduledoc """
  Converts inbound message handler outputs into sendable action nodes.
  """

  @type receipt_builder ::
          (String.t(), String.t(), String.t() | nil, String.t() | nil -> term())

  @type retry_receipt_builder ::
          (String.t(),
           String.t(),
           String.t()
           | nil,
           String.t()
           | integer()
           | nil,
           non_neg_integer()
           | nil,
           integer()
           | nil,
           map()
           | nil ->
             term())

  @spec handle_message_node(
          ExWapp.Binary.Node.t(),
          map(),
          receipt_builder(),
          retry_receipt_builder()
        ) :: {map(), list()}
  def handle_message_node(node, state, build_receipt_ack, build_retry_receipt_ack) do
    case ExWapp.MessageHandler.handle_node(node, self(), state) do
      {:ok, new_state} ->
        {new_state, []}

      {:ok, new_state, actions} ->
        converted_actions =
          Enum.map(actions, fn
            {:send_receipt, to, id, participant, type} ->
              {:send_node, build_receipt_ack.(to, id, participant, type)}

            {:send_retry_receipt, to, id, participant, message_t, retry_count, error_code,
             retry_meta} ->
              {:send_node,
               build_retry_receipt_ack.(
                 to,
                 id,
                 participant,
                 message_t,
                 retry_count,
                 error_code,
                 retry_meta
               )}

            other ->
              other
          end)

        {new_state, converted_actions}
    end
  end
end
