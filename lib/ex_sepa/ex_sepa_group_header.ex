defmodule ExSepa.GroupHeader do
  import XmlBuilder

  @moduledoc """
  Group Header: Set of characteristics shared by all individual transactions included in the message.
  """

  @enforce_keys [:msg_id, :initiating_party_name]
  @typedoc """
  The map has the following keys:
    * `:msg_id` - Message Identification: Point to point reference, assigned by the instructing party and sent to the next party in the chain, to unambiguously identify the message (maximum length of 35 characters).
    * `:initiating_party_name`- Initiating Party Name: Name by which a party is known and which is usually used to identify that party (maximum length of 70 characters).
  """
  @type t :: %__MODULE__{
          msg_id: String.t(),
          initiating_party_name: String.t()
        }
  defstruct [:msg_id, :initiating_party_name]

  @doc """
  Returns a new group header with the given arguments.

  ## Examples

      iex> ExSepa.GroupHeader.new("Message-ID-4711", "Initiator Name")
      {:ok, %ExSepa.GroupHeader{msg_id: "Message-ID-4711", initiating_party_name: "Initiator Name"}}

  """
  @spec new(String.t(), String.t()) :: {:error, String.t()} | {:ok, struct()}
  def new(msg_id, initiating_party_name)
      when is_binary(msg_id) and is_binary(initiating_party_name) do
    with :ok <- max_text(:msg_id, msg_id, 35),
         :ok <- ExSepa.in_language(msg_id),
         :ok <- max_text(:initiating_party_name, initiating_party_name, 70),
         :ok <- ExSepa.in_language(initiating_party_name) do
      {:ok, struct(__MODULE__, msg_id: msg_id, initiating_party_name: initiating_party_name)}
    else
      {:error, e} -> {:error, e}
    end
  end

  def new(msg_id, initiating_party_name) do
    error_text = "Parameters must be strings."

    error_text =
      case real_text(:msg_id, msg_id) do
        {:error, e} ->
          error_text <> " - " <> e

        _ ->
          error_text
      end

    error_text =
      case real_text(:initiating_party_name, initiating_party_name) do
        {:error, e} ->
          error_text <> " - " <> e

        _ ->
          error_text
      end

    {:error, error_text}
  end

  defp real_text(element, text) do
    case is_binary(text) do
      true ->
        case String.valid?(text) do
          true ->
            :ok

          # case ExSepa.in_language(text) do
          #   :ok -> :ok
          #   {:error, e} -> {:error, "#{element} - #{e}"}
          # end

          _ ->
            {:error, "#{element}: must be UTF-8 encoded binary"}
        end

      _ ->
        {:error, "#{element}: must be UTF-8 encoded binary"}
    end
  end

  defp max_text(element, text, max_length) do
    case real_text(element, text) do
      :ok ->
        case String.length(text) do
          x when x <= max_length -> :ok
          _ -> {:error, "#{element}: maximum length of #{max_length} characters"}
        end

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  @spec to_xml(t(), non_neg_integer(), float()) :: {atom(), any(), any()}
  def to_xml(%__MODULE__{} = group_header, nb_of_txs, ctrl_sum) do
    element(:GrpHdr, nil, [
      element(:MsgId, nil, group_header.msg_id),
      element(:CreDtTm, nil, DateTime.to_iso8601(DateTime.utc_now(:second))),
      element(:NbOfTxs, nil, nb_of_txs),
      element(:CtrlSum, nil, ctrl_sum),
      element(:InitgPty, nil, [
        element(:Nm, nil, group_header.initiating_party_name)
      ])
    ])
  end
end
