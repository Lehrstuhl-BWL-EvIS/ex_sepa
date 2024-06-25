defmodule ExSepa.PaymentInformation do
  import XmlBuilder

  @moduledoc false
  # """
  # # Payment Information
  #
  # Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.
  # """

  @enforce_keys [:pmtInfId, :reqdColltnDt, :cdtrNm, :cdtrAcctIban, :cdtrAgtBic, :cdtrId]
  defstruct [
    :pmtInfId,
    :reqdColltnDt,
    :cdtrNm,
    :cdtrAcctIban,
    :cdtrAgtBic,
    :cdtrId,
    :seqTp
  ]

  @type t :: %__MODULE__{
          # Payment Id
          pmtInfId: binary(),
          # Due Date
          reqdColltnDt: Date.t(),
          # Creditor Name
          cdtrNm: binary(),
          # IBAN
          cdtrAcctIban: binary(),
          # BIC
          cdtrAgtBic: binary(),
          # Creditor Indentification
          cdtrId: binary(),
          # "FRST", "RCUR", "FNAL" or "OOFF"
          seqTp: binary()
        }

  @doc """
  pmtInfId: Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message.

  reqdColltnDt: The Due Date of the Collection. Date and time at which the creditor requests that the amount of money is to be collected from the debtor.

  cdtrNm: The Name of the Creditor. Name by which a party is known and which is usually used to identify that party. Limited to 70 characters in length.

  cdtrAcctIban: The account number (IBAN) of the Creditor. Unambiguous identification of the account of the creditor to which a credit entry will be posted as a result of the payment transaction.

  cdtrAgtBic: BIC code of the Creditor PSP. Code allocated to a financial institution by the ISO 9362 Registration Authority as described in ISO 9362 "Banking - Banking telecommunication messages - Business identifier code (BIC)".

  cdtrId: Unique identification of a person, as assigned by an institution, using an identification scheme.

  seqTp: Mandatory. If ‘Amendment Indicator’ is "true", and ‘Original Debtor Account’ is set to "SMNDA" (Same Mandate with a New Debtor Account), this message element indicates either "FRST", "RCUR", "FNAL" or "OOFF" (all four codes allowed, no restrictions).

  ## Examples

      iex> new("Payment-ID-4711", Date.utc_today() |> Date.add(5), "Creditor Name", "DE87200500001234567890", "BANKDEFFXXX", "DE00ZZZ00099999999")
      %ExSepa.Pmtinf{
        pmtInfId: "Payment-ID-4711",
        reqdColltnDt: ~D[2024-06-21],
        cdtrNm: "Creditor Name",
        cdtrAcctIban: "DE87200500001234567890",
        cdtrAgtBic: "BANKDEFFXXX",
        cdtrId: "DE00ZZZ00099999999",
        seqTp: "OOFF"
      }

      iex> new("Payment-ID-4711", Date.utc_today() |> Date.add(5), "Creditor Name", "DE87200500001234567890", "BANKDEFFXXX", "DE00ZZZ00099999999", "FRST")
      %ExSepa.Pmtinf{
        pmtInfId: "Payment-ID-4711",
        reqdColltnDt: ~D[2024-06-21],
        cdtrNm: "Creditor Name",
        cdtrAcctIban: "DE87200500001234567890",
        cdtrAgtBic: "BANKDEFFXXX",
        cdtrId: "DE00ZZZ00099999999",
        seqTp: "FRST"
      }
  """
  def new(
        pmt_inf_id,
        reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        cdtr_agt_bic,
        cdtr_id,
        seq_tp \\ "OOFF"
      )

  def new(
        pmt_inf_id,
        %Date{} = reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        cdtr_agt_bic,
        cdtr_id,
        seq_tp
      )
      when is_binary(pmt_inf_id) and is_binary(cdtr_nm) and is_binary(cdtr_acct_iban) and
             is_binary(cdtr_agt_bic) and is_binary(cdtr_id) and is_binary(seq_tp) do
    {:ok,
     %__MODULE__{
       pmtInfId: pmt_inf_id,
       reqdColltnDt: reqd_colltn_dt,
       cdtrNm: cdtr_nm,
       cdtrAcctIban: cdtr_acct_iban,
       cdtrAgtBic: cdtr_agt_bic,
       cdtrId: cdtr_id,
       seqTp: seq_tp
     }}
  end

  def new(
        pmt_inf_id,
        _reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        cdtr_agt_bic,
        cdtr_id,
        seq_tp
      )
      when is_binary(pmt_inf_id) and is_binary(cdtr_nm) and is_binary(cdtr_acct_iban) and
             is_binary(cdtr_agt_bic) and is_binary(cdtr_id) and is_binary(seq_tp) do
    {:error, {__MODULE__, "Parameters reqd_colltn_dt must be a date"}}
  end

  def new(
        _pmt_inf_id,
        _reqd_colltn_dt,
        _cdtr_nm,
        _cdtr_acct_iban,
        _cdtr_agt_bic,
        _cdtr_id,
        _seq_tp
      ) do
    {:error, {__MODULE__, "Parameters must be strings"}}
  end

  def create(%__MODULE__{} = pmtinf, drct_dbt_tx_inf, nb_of_txs, ctrl_sum)
      when is_integer(nb_of_txs) and is_float(ctrl_sum) do
    # SG: 1..n TYPE = PaymentInstruction29
    element(:PmtInf, nil, [
      # SG: Type = Max35Text -> Length 1 .. 35
      element(:PmtInfId, nil, pmtinf.pmtInfId),
      # SG: TYPE = PaymentMethod2Code
      element(:PmtMtd, nil, "DD"),
      # SG: OPTIONAL! TYPE = BatchBookingIndicator -> If present and contains "true", batch booking is requested. If present and contains "false", booking per transaction is requested. If element is not present, pre-agreed customer-to-PSP conditions apply.
      # element(:BtchBookg, nil, btchBookg)
      # SG: Type = Max15NumericText -> Pattern = [0-9]{1,15}
      element(:NbOfTxs, nil, nb_of_txs),
      # SG: Type = DecimalNumber -> TotalDigits = 18, FractDigits = 2
      element(:CtrlSum, nil, ctrl_sum),
      # SG: OPTIONAL! Type = PaymentTypeInformation29 -> ‘Payment Type Information’ must be present either here or under ‘Direct Debit Transaction Information’.
      element(:PmtTpInf, nil, [
        # SG: Type = ServiceLevel8Choice -> Mandatory. Only one occurence is allowed.
        element(:SvcLvl, nil, [
          # SG: Type = ExternalServiceLevel1Code -> Only "SEPA" is allowed.
          element(:Cd, nil, "SEPA")
        ]),
        # SG: Type = LocalInstrument2Choice -> Mandatory.
        element(:LclInstrm, nil, [
          # SG: Type = ExternalLocalInstrument1Code -> Only "CORE" is allowed.
          element(:Cd, nil, "CORE")
        ]),
        # SG: Type = SequenceType3Code -> Mandatory. If ‘Amendment Indicator’ is "true", and ‘Original Debtor Account’ is set to "SMNDA" (Same Mandate with a New Debtor Account), this message element indicates either "FRST", "RCUR", "FNAL" or "OOFF" (all four codes allowed, no restrictions).
        element(:SeqTp, nil, pmtinf.seqTp)
        # SG: OPTIONAL! Type = CategoryPurpose1Choice
        # element(:CtgyPurp, nil, [
        # SG: Type = ExternalCategoryPurpose1Code
        # element(:Cd, nil, ctgyPurpCd),
        # SG: Type = Max35Text -> Length 1 .. 35
        # element(:Prtry, nil, ctgyPurpPrtry)
        # ])
      ]),
      # SG: Type = ISODate -> AT-T013 The Due Date of the Collection.
      element(:ReqdColltnDt, nil, pmtinf.reqdColltnDt),
      # SG: Type = PartyIdentification135
      element(:Cdtr, nil, [
        # SG: Type = Max140Text -> Length 1 .. 70
        element(:Nm, nil, pmtinf.cdtrNm)
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
      # SG: Type = CashAccount38 -> AT-C001 The account number (IBAN) of the Creditor.
      element(:CdtrAcct, nil, [
        # SG: Type = AccountIdentification4Choice -> Only IBAN is allowed.
        element(:Id, nil, [
          # SG: Type =
          element(:IBAN, nil, pmtinf.cdtrAcctIban)
          # SG: OPTIONAL! Type = ActiveOrHistoricCurrencyCode -> Pattern = [A-Z]{3,3}
          # element(:Ccy, nil, cdtrAcctCcy)
        ])
      ]),
      # SG: Type = BranchAndFinancialInstitutionIdentification6 -> Creditor Agent
      element(:CdtrAgt, nil, [
        # SG: Type = FinancialInstitutionIdentification18 -> Either 'BICFI' or ‘Other/Identification’ must be used.
        element(:FinInstnId, nil, [
          # SG: Type = BICFIDec2014Identifier -> AT-C002 BIC code of the Creditor PSP. -> Pattern = [A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}
          element(:BICFI, nil, pmtinf.cdtrAgtBic)
          # SG: Type = GenericFinancialIdentification1
          # element(:Othr, nil, [
          # SG: Type = Max35Text -> Length 1 .. 35 -> Only "NOTPROVIDED" is allowed.
          # element(:Id, nil, cdtrAgtFinInstnIdOtherId)
          # ])
        ])
      ]),
      # SG: OPTIONAL! Type = PartyIdentification135 -> This data element may be present either at 'Payment Information' or at 'Direct Debit Transaction Information' level.
      # element(:UltmtCdtr, nil, [
      # SG: Type = Max140Text  -> Length 1 .. 70 -> AT-E007 The Name of the Creditor Reference Party.
      # element(:Nm, nil, ultmtCdtrNm)
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
        # SG: Type = Party38Choice
        element(:Id, nil, [
          # SG: Type = PersonIdentification13
          element(:PrvtId, nil, [
            # SG: Type = GenericPersonIdentification1 -> Mandatory. Only one occurrence of ‘Other’ is allowed, and no other sub-elements are allowed. 'Identification' must be used with an identifier described in General Message Element Specifications, Chapter 1.5.2. ‘Proprietary’ under ‘Scheme Name’ must specify "SEPA".
            element(:Othr, nil, [
              # SG: Type = ???
              element(:Id, nil, pmtinf.cdtrId),
              # SG: Type = FinancialIdentificationSchemeName1Choice
              element(:SchmeNm, nil, [
                # SG: Type = Max35Text
                element(:Prtry, nil, "SEPA")
              ])
            ])
          ])
        ])
      ]),
      drct_dbt_tx_inf
    ])
  end
end
