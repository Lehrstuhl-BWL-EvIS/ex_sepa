defmodule ExSepa.PaymentInformation do
  import XmlBuilder

  alias ExSepa.Validation

  @moduledoc """
  Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.
  """

  # Identifies the direct debit sequence, such as first, recurrent, final or one-off.
  @sequence_type3_code_atom [:OneOff, :First, :Recurring, :Final]
  @sequence_type3_code %{OneOff: "OOFF", First: "FRST", Recurring: "RCUR", Final: "FNAL"}

  @enforce_keys [:payment_id, :due_date, :creditor_id, :creditor_name, :creditor_iban]
  @typedoc """
  The map has the following keys:

    * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
    * `:due_date` - The Due Date of the Collection (ISODate).
    * `:creditor_id` - Unique and unambiguous identification of a party (maximum length of 35 characters.).
    * `:creditor_name` - The Name of the Creditor (maximum length of 70 characters).
    * `:creditor_iban` - The account number (IBAN) of the Creditor.
    * `:creditor_bic` - BIC code of the Creditor PSP.
    * `:sequence_type` - Identifies the direct debit sequence, such as first, recurrent, final or one-off ("FRST", "RCUR", "FNAL" or "OOFF").
  """
  @type t :: %__MODULE__{
          payment_id: String.t(),
          due_date: Date.t(),
          creditor_id: String.t(),
          creditor_name: String.t(),
          creditor_iban: String.t(),
          creditor_bic: String.t(),
          sequence_type: atom()
        }

  defstruct [
    :payment_id,
    :due_date,
    :creditor_name,
    :creditor_iban,
    :creditor_bic,
    :creditor_id,
    :sequence_type
  ]

  @doc false
  @spec new(String.t(), Date.t(), String.t(), String.t(), String.t(), String.t(), atom()) ::
          {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic \\ "",
        sequence_type \\ :OneOff
      )

  def new(
        payment_id,
        %Date{} = due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic,
        sequence_type
      )
      when is_binary(payment_id) and is_binary(creditor_name) and is_binary(creditor_iban) and
             is_binary(creditor_bic) and is_binary(creditor_id) and
             sequence_type in @sequence_type3_code_atom do
    with :ok <- Validation.max_35_text(:payment_id, payment_id),
         :ok <- Validation.due_date(due_date),
         :ok <- Validation.max_35_text(:creditor_id, creditor_id),
         :ok <- Validation.max_70_text(:creditor_name, creditor_name),
         :ok <- Validation.iban(creditor_iban),
         :ok <- Validation.bic(creditor_bic) do
      {:ok,
       %__MODULE__{
         payment_id: payment_id,
         due_date: due_date,
         creditor_id: creditor_id,
         creditor_name: creditor_name,
         creditor_iban: creditor_iban,
         creditor_bic: creditor_bic,
         sequence_type: sequence_type
       }}
    else
      {:error, e} -> {:error, e}
    end
  end

  def new(
        payment_id,
        _due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic,
        sequence_type
      )
      when is_binary(payment_id) and is_binary(creditor_name) and is_binary(creditor_iban) and
             is_binary(creditor_bic) and is_binary(creditor_id) and
             sequence_type in @sequence_type3_code_atom do
    {:error, "Parameter due_date must be a date"}
  end

  def new(
        payment_id,
        _due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic,
        sequence_type
      )
      when is_binary(payment_id) and is_binary(creditor_name) and is_binary(creditor_iban) and
             is_binary(creditor_bic) and is_binary(creditor_id) and is_atom(sequence_type) do
    {:error,
     "Parameter sequence_type must be an atom :#{Enum.join(@sequence_type3_code_atom, ", :")}"}
  end

  def new(
        payment_id,
        _due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic,
        sequence_type
      )
      when is_binary(payment_id) and is_binary(creditor_name) and is_binary(creditor_iban) and
             is_binary(creditor_bic) and is_binary(creditor_id) and
             is_atom(sequence_type) == false do
    {:error,
     "Parameter sequence_type must be an atom :#{Enum.join(@sequence_type3_code_atom, ", :")}"}
  end

  def new(
        payment_id,
        _due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic,
        _sequence_type
      ) do
    Validation.text(
      [
        {:payment_id, payment_id},
        {:creditor_id, creditor_id},
        {:creditor_name, creditor_name},
        {:creditor_iban, creditor_iban},
        {:creditor_bic, creditor_bic}
      ],
      "Parameters must be strings."
    )
  end

  @doc false
  def to_xml(
        %__MODULE__{} = payment_information,
        transaction_information,
        number_of_transactions,
        control_sum
      )
      when is_integer(number_of_transactions) and is_float(control_sum) do
    element(:PmtInf, nil, [
      element(:PmtInfId, nil, payment_information.payment_id),
      element(:PmtMtd, nil, "DD"),
      # SG: OPTIONAL! TYPE = BatchBookingIndicator -> If present and contains "true", batch booking is requested. If present and contains "false", booking per transaction is requested. If element is not present, pre-agreed customer-to-PSP conditions apply.
      # element(:BtchBookg, nil, btchBookg)
      element(:NbOfTxs, nil, number_of_transactions),
      element(:CtrlSum, nil, control_sum),
      element(:PmtTpInf, nil, [
        element(:SvcLvl, nil, [
          element(:Cd, nil, "SEPA")
        ]),
        element(:LclInstrm, nil, [
          element(:Cd, nil, "CORE")
        ]),
        element(:SeqTp, nil, @sequence_type3_code[payment_information.sequence_type])
        # SG: OPTIONAL! Type = CategoryPurpose1Choice
        # element(:CtgyPurp, nil, [
        # SG: Type = ExternalCategoryPurpose1Code
        # element(:Cd, nil, ctgyPurpCd),
        # SG: Type = Max35Text -> Length 1 .. 35
        # element(:Prtry, nil, ctgyPurpPrtry)
        # ])
      ]),
      element(:ReqdColltnDt, nil, payment_information.due_date),
      element(:Cdtr, nil, [
        element(:Nm, nil, payment_information.creditor_name)
        # SG: Type = PostalAddress24 -> If ‘Address Line’ is used, then ‘Postal Address’ sub-elements other than ‘Country’ are forbidden. A combination of ‘Address Line’ and 'Country’ is allowed. If 'Address Line' is not used, then at least 'Town Name' and 'Country' must be used.
        # element(:PstlAdr, nil, [
        # SG: OPTIONAL! Type = Max70Text -> Length 1 .. 70
        # element(:Dept, nil, pstlAdrDept)
        # SG: OPTIONAL! Type = Max70Text -> Length 1 .. 70
        # element(:SubDept, nil, pstlAdrSubDept)
        # SG: OPTIONAL! Type = Max70Text -> Length 1 .. 70
        # element(:StrtNm, nil, pstlAdrStrtNm)
        # SG: OPTIONAL! Type = Max16Text -> Length 1 .. 16
        # element(:BldgNb, nil, pstlAdrBldgNb)
        # SG: OPTIONAL! Type = Max35Text -> Length 1 .. 35
        # element(:BldgNm, nil, pstlAdrBldgNm)
        # SG: OPTIONAL! Type = Max70Text -> Length 1 .. 70
        # element(:Flr, nil, pstlAdrFlr)
        # SG: OPTIONAL! Type = Max16Text -> Length 1 .. 16
        # element(:PstBx, nil, pstlAdrPstBx)
        # SG: OPTIONAL! Type = Max70Text -> Length 1 .. 70
        # element(:Room, nil, pstlAdrRoom)
        # SG: OPTIONAL! Type = Max16Text -> Length 1 .. 16
        # element(:PstCd, nil, pstlAdrPstCd)
        # SG: OPTIONAL! Type = Max35Text -> Length 1 .. 35
        # element(:TwnNm, nil, pstlAdrTwnNm)
        # SG: OPTIONAL! Type = Max35Text -> Length 1 .. 35
        # element(:TwnLctnNm, nil, pstlAdrTwnLctnNm)
        # SG: OPTIONAL! Type = Max35Text -> Length 1 .. 35
        # element(:DstrctNm, nil, pstlAdrDstrctNm)
        # SG: OPTIONAL! Type = Max35Text -> Length 1 .. 35
        # element(:CtrySubDvsn, nil, pstlAdrCtrySubDvsn)
        # SG: OPTIONAL! Type = CountryCode -> [A-Z]{2,2}
        # element(:Ctry, nil, pstlAdrCtry)
        # SG: 0..2 Type = Max70Text -> Length 1 .. 70 -> Only two occurrences are allowed. If ‘Address Line’ is used, then ‘Postal Address’ sub-elements other than ‘Country’ are forbidden. A combination of ‘Address Line’ and 'Country’ is allowed.
        # element(:AdrLine, nil, pstlAdrAdrLine)
        # ])
      ]),
      element(:CdtrAcct, nil, [
        element(:Id, nil, [
          element(:IBAN, nil, payment_information.creditor_iban)
          # SG: OPTIONAL! Type = ActiveOrHistoricCurrencyCode -> Pattern = [A-Z]{3,3}
          # element(:Ccy, nil, cdtrAcctCcy)
        ])
      ]),
      element(:CdtrAgt, nil, [
        element(:FinInstnId, nil, [
          if payment_information.creditor_bic == "" do
            element(:Othr, nil, [
              element(:Id, nil, "NOTPROVIDED")
            ])
          else
            element(:BICFI, nil, payment_information.creditor_bic)
          end
        ])
      ]),
      # SG: OPTIONAL! Type = PartyIdentification135 -> This data element may be present either at 'Payment Information' or at 'Direct Debit Transaction Information' level.
      # element(:UltmtCdtr, nil, [
      # SG: Type = Max140Text  -> Length 1 .. 70 -> AT-E007 The Name of the Creditor Reference Party.
      # element(:Nm, nil, ultmtcreditor_name)
      # SG: OPTIONAL! Type = Party38Choice
      # element(:Id, nil, [
      # SG: xs:choice! Type = OrganisationIdentification29 -> Either ‘AnyBIC’, 'LEI' or one occurrence of ‘Other’ is allowed.
      # initgPtyId = element(:OrgId, nil, initgPtyIdOrgId)
      # SG: xs:choice! Type = PersonIdentification13 -> Either ‘Date and Place of Birth’ or one occurrence of ‘Other’ is allowed.
      # initgPtyId = element(:PrvtId, nil, initgPtyIdPrvtId)
      # ])
      # ]),
      # SG: OPTIONAL! Type = ChargeBearerType1Code -> Only "SLEV" is allowed. It is recommended that this element be specified at ‘Payment Information’ level.
      # element(:ChrgBr, nil, "SLEV"),
      # SG: OPTIONAL! Type = PartyIdentification135 -> It is recommended that all transactions within the same ‘Payment Information’ block have the same ‘Creditor Scheme Identification’. This data element must be present at either ‘Payment Information’ or ‘Direct Debit Transaction’ level.
      element(:CdtrSchmeId, nil, [
        element(:Id, nil, [
          element(:PrvtId, nil, [
            element(:Othr, nil, [
              element(:Id, nil, payment_information.creditor_id),
              element(:SchmeNm, nil, [
                element(:Prtry, nil, "SEPA")
              ])
            ])
          ])
        ])
      ]),
      transaction_information
    ])
  end
end
