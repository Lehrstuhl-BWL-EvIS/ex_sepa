defmodule ExSepa.GroupHeader do
  import XmlBuilder

  alias ExSepa.Validation

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

  @doc false
  @spec new(map()) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{"msg_id" => msg_id, "initiating_party_name" => initiating_party_name} =
          _group_header_map
      )
      when is_binary(msg_id) and is_binary(initiating_party_name) do
    with :ok <- Validation.max_35_text(:msg_id, msg_id),
         :ok <- Validation.max_70_text(:initiating_party_name, initiating_party_name) do
      {:ok, %__MODULE__{msg_id: msg_id, initiating_party_name: initiating_party_name}}
    end
  end

  def new(group_header_map) do
    if Map.has_key?(group_header_map, "msg_id") do
      if Map.has_key?(group_header_map, "initiating_party_name") do
        Validation.text(
          [
            {:msg_id, group_header_map["msg_id"]},
            {:initiating_party_name, group_header_map["initiating_party_name"]}
          ],
          "Parameters must be strings."
        )
      else
        {:error, "key initiating_party_name is missing"}
      end
    else
      {:error, "key msg_id is missing"}
    end
  end

  @doc false
  @spec to_xml(__MODULE__.t(), non_neg_integer(), float()) :: {atom(), any(), any()}
  def to_xml(%__MODULE__{} = group_header, number_of_transactions, control_sum) do
    element(:GrpHdr, nil, [
      element(:MsgId, nil, group_header.msg_id),
      element(:CreDtTm, nil, DateTime.to_iso8601(DateTime.utc_now(:second))),
      element(:NbOfTxs, nil, number_of_transactions),
      element(:CtrlSum, nil, control_sum),
      element(:InitgPty, nil, [
        element(:Nm, nil, group_header.initiating_party_name)
      ])
    ])
  end
end
