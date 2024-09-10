defmodule ExSepa.CustomerDirectDebitInitiationV08 do
  import XmlBuilder

  @moduledoc false
  # """
  # CustomerDirectDebitInitiationV08 (pain.008.001.08)

  # The CustomerDirectDebitInitiation message is sent by the initiating party to the forwarding agent or creditor agent.
  # It is used to request single or bulk collection(s) of funds from one or various debtor's account(s) for a creditor.
  # """

  @doc false
  @spec to_xml(ExSepa.DirectDebit.t()) :: String.t()
  def to_xml(%ExSepa.DirectDebit{} = direct_debit) do
    {info, number_of_transactions, control_sum} =
      do_to_xml({direct_debit.payment_information, 0, 0.0})

    xb_document(
      element(:CstmrDrctDbtInitn, nil, [
        direct_debit.group_header
        |> to_xml_group_header(number_of_transactions, control_sum)
        | info
      ])
    )
  end

  defp do_to_xml({[], number_of_transactions, control_sum}),
    do: {[], number_of_transactions, control_sum}

  defp do_to_xml(
         {[%ExSepa.PaymentInformation{} = first | rest], number_of_transactions, control_sum}
       ) do
    if first.transaction_information != [] do
      count = length(first.transaction_information)

      sum =
        Float.round(
          Enum.reduce(first.transaction_information, 0, fn %ExSepa.TransactionInformation{} = v,
                                                           acc ->
            v.amount + acc
          end) * 1.0,
          2
        )

      {new_rest, new_number_of_transactions, new_control_sum} =
        do_to_xml({rest, number_of_transactions + count, control_sum + sum})

      {[
         to_xml_payment_information(
           first,
           count,
           sum
         )
         | new_rest
       ], new_number_of_transactions, new_control_sum}
    else
      {new_rest, new_number_of_transactions, new_control_sum} =
        do_to_xml({rest, number_of_transactions, control_sum})

      {[new_rest], new_number_of_transactions, new_control_sum}
    end
  end

  defp xb_document(content) do
    doc =
      document(
        {:Document,
         [
           xmlns: "urn:iso:std:iso:20022:tech:xsd:pain.008.001.08",
           "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
           "xsi:schemaLocation":
             "urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd"
         ], [content]}
      )

    doc
    |> generate()
  end

  @doc false
  defp to_xml_group_header(
         %ExSepa.GroupHeader{} = group_header,
         number_of_transactions,
         control_sum
       ) do
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

  @doc false
  defp to_xml_payment_information(
         %ExSepa.PaymentInformation{} = payment_information,
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
        element(
          :SeqTp,
          nil,
          ExSepa.PaymentInformation.get_sequenz_type_code(payment_information.sequence_type)
        )
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
        element(:Nm, nil, payment_information.creditor_name),
        if payment_information.creditor_address != nil do
          to_xml_address(payment_information.creditor_address)
        end
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
      element(:ChrgBr, nil, "SLEV"),
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
      to_xml_transaction_information(payment_information.transaction_information)
    ])
  end

  @doc false
  @spec to_xml_transaction_information([ExSepa.TransactionInformation.t()]) :: list()
  def to_xml_transaction_information([]), do: []

  def to_xml_transaction_information([%ExSepa.TransactionInformation{} = first | rest]) do
    [do_to_xml_transaction_information(first) | to_xml_transaction_information(rest)]
  end

  defp do_to_xml_transaction_information(
         %ExSepa.TransactionInformation{} = transaction_information
       ) do
    element(:DrctDbtTxInf, nil, [
      element(:PmtId, nil, [
        element(
          :EndToEndId,
          nil,
          if transaction_information.end_to_end_id |> String.trim() == "" do
            "NOTPROVDED"
          else
            transaction_information.end_to_end_id |> String.trim()
          end
        )
      ]),
      element(:InstdAmt, %{Ccy: "EUR"}, transaction_information.amount),
      element(:DrctDbtTx, nil, [
        element(:MndtRltdInf, nil, [
          element(:MndtId, nil, transaction_information.mandate_id),
          element(:DtOfSgntr, nil, transaction_information.mandate_signing_date)
        ])
      ]),
      element(:DbtrAgt, nil, [
        element(:FinInstnId, nil, [
          if transaction_information.debtor_bic |> String.trim() == "" do
            element(:Othr, nil, [
              element(:Id, nil, "NOTPROVIDED")
            ])
          else
            element(:BICFI, nil, transaction_information.debtor_bic)
          end
        ])
      ]),
      element(:Dbtr, nil, [
        element(:Nm, nil, transaction_information.debtor_name),
        if transaction_information.debtor_address != nil do
          to_xml_address(transaction_information.debtor_address)
        end
      ]),
      element(:DbtrAcct, nil, [
        element(:Id, nil, [
          element(:IBAN, nil, transaction_information.debtor_iban)
        ])
      ]),
      element(:RmtInf, nil, [
        element(:Ustrd, nil, transaction_information.remittance_information)
      ])
    ])
  end

  @doc false
  @spec to_xml_address(ExSepa.Address.t()) :: {atom(), any(), any()}
  def to_xml_address(%ExSepa.Address{} = address_map) do
    element(:PstlAdr, nil, [
      if address_map.department != nil do
        element(:Dept, nil, address_map.department)
      end,
      if address_map.sub_department != nil do
        element(:SubDept, nil, address_map.sub_department)
      end,
      if address_map.street_name != nil do
        element(:StrtNm, nil, address_map.street_name)
      end,
      if address_map.building_number != nil do
        element(:BldgNb, nil, address_map.building_number)
      end,
      if address_map.building_name != nil do
        element(:BldgNm, nil, address_map.building_name)
      end,
      if address_map.floor != nil do
        element(:Flr, nil, address_map.floor)
      end,
      if address_map.post_box != nil do
        element(:PstBx, nil, address_map.post_box)
      end,
      if address_map.room != nil do
        element(:Room, nil, address_map.room)
      end,
      if address_map.post_code != nil do
        element(:PstCd, nil, address_map.post_code)
      end,
      element(:TwnNm, nil, address_map.town_name),
      if address_map.town_location_name != nil do
        element(:TwnLctnNm, nil, address_map.town_location_name)
      end,
      if address_map.district_name != nil do
        element(:DstrctNm, nil, address_map.district_name)
      end,
      if address_map.country_sub_division != nil do
        element(:CtrySubDvsn, nil, address_map.country_sub_division)
      end,
      element(:Ctry, nil, address_map.country)
    ])
  end
end
