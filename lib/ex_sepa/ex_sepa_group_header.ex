defmodule ExSepa.GroupHeader do
  import XmlBuilder

  @moduledoc false
  # """
  # GroupHeader: Set of characteristics shared by all individual transactions included in the message.
  # """

  @enforce_keys [:msgId, :initgPtyNm]
  @type t :: %__MODULE__{
          msgId: String.t(),
          initgPtyNm: String.t()
        }
  defstruct [:msgId, :initgPtyNm]

  @doc """
  Message Identification: Point to point reference, assigned by the instructing party and sent to the next party in the chain, to unambiguously identify the message.
  Usage: The instructing party has to make sure that MessageIdentification is unique per instructed party for a pre-agreed period.
  Specifies a character string with a maximum length of 35 characters.

  Initiating Party Name: Name by which a party is known and which is usually used to identify that party.
  Specifies a character string with a maximum length of 140 characters.

  ## Examples

      iex> ExSepa.GroupHeader.new("Message-ID-4711", "Initiator Name")
      {:ok, %ExSepa.GroupHeader{msgId: "Message-ID-4711", initgPtyNm: "Initiator Name"}}

  """
  @spec new(String.t(), String.t()) ::
          {:error, {ExSepa.GroupHeader, String.t()}} | {:ok, struct()}
  def new(msg_id, initg_pty_nm) when is_binary(msg_id) and is_binary(initg_pty_nm) do
    struct = struct(__MODULE__, msgId: msg_id, initgPtyNm: initg_pty_nm)

    with :ok <- max_text(:msgId, msg_id, 35),
         :ok <- max_text(:initgPtyNm, initg_pty_nm, 70) do
      {:ok, struct}
    else
      {:error, e} -> {:error, {__MODULE__, e}}
    end
  end

  def new(msg_id, initg_pty_nm) do
    error_text = "Parameters must be strings."

    error_text =
      case real_text(:msgId, msg_id) do
        {:error, e} ->
          error_text <> " - " <> e

        _ ->
          error_text
      end

    error_text =
      case real_text(:initgPtyNm, initg_pty_nm) do
        {:error, e} ->
          error_text <> " - " <> e

        _ ->
          error_text
      end

    {:error, {__MODULE__, error_text}}
  end

  defp real_text(element, text) do
    case is_binary(text) do
      true ->
        case String.valid?(text) do
          true -> :ok
          _ -> {:error, "#{element}: must be UTF-8 encoded binary"}
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
  def to_xml(%__MODULE__{} = grphdr, nb_of_txs, ctrl_sum) do
    # SG: creDtTm: Date and time at which the message was created. Gets the time only by seconds.
    cre_dt_tm = DateTime.utc_now(:second)

    # SG: Type = GroupHeader83
    element(:GrpHdr, nil, [
      # SG: Type = Max35Text -> Length 1 .. 35
      element(:MsgId, nil, grphdr.msgId),
      # SG: Type = ISODateTime
      element(:CreDtTm, nil, cre_dt_tm |> DateTime.to_iso8601()),
      # SG: Type = Max15NumericText -> Pattern = [0-9]{1,15}
      element(:NbOfTxs, nil, nb_of_txs),
      # SG: Type = DecimalNumber -> TotalDigits = 18, FractDigits = 2
      element(:CtrlSum, nil, ctrl_sum),
      # SG: Type = PartyIdentification135
      element(:InitgPty, nil, [
        # SG: OPTIONAL! Type = Max140Text -> Length 1 .. 70
        element(:Nm, nil, grphdr.initgPtyNm)
        # element(:Id, nil, [initgPtyId])  # SG: OPTIONAL! Type = Party38Choice
        # initgPtyId = element(:OrgId, nil, initgPtyIdOrgId)  # SG: xs:choice! Type = OrganisationIdentification29 -> Either ‘AnyBIC’, 'LEI' or one occurrence of ‘Other’ is allowed.
        # initgPtyId = element(:PrvtId, nil, initgPtyIdPrvtId)  # SG: xs:choice! Type = PersonIdentification13 -> Either ‘Date and Place of Birth’ or one occurrence of ‘Other’ is allowed.
      ])
    ])
  end
end
