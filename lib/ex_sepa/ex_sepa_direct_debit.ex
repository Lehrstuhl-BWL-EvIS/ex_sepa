defmodule ExSepa.DirectDebit do
  @moduledoc """
  Documentation for `ExSepa.DirectDebit`.

  This library is based on the structure of the SEPA Core Direct Debit Scheme.

  The `new()` function is used to create a new direct debit transaction initiation message.
  Now one or more payment information messages can be added using the `add_payment_information()` function.
  Subsequently, at least one transaction information must be added to each payment information with the `add_transaction_information()` command.
  Finally, the `to_xml()` function returns the data in the ISO 20022 XML message standard.
  """

  # Identifies the direct debit sequence, such as first, recurrent, final or one-off.
  @sequence_type3_code_atom [:OneOff, :First, :Recurring, :Final]
  @sequence_type3_code %{OneOff: "OOFF", First: "FRST", Recurring: "RCUR", Final: "FNAL"}

  @doc """
  Creates a new Direct Debit with a `Unique Message Id` and `Initiating Party Name`

  ## Example

      direct_debit = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")
  """
  def new(msg_id, initiating_party) do
    if String.valid?(msg_id) do
      if String.valid?(initiating_party) do
        do_directdebit_new(msg_id, initiating_party)
      else
        {:error, "initiating_party is not a String"}
      end
    else
      {:error, "msg_id is not a String"}
    end
  end

  defp do_directdebit_new(msg_id, initiating_party) do
    ExSepa.CustomerDirectDebitInitiationV08.new(msg_id, initiating_party)
  end

  @doc """
  Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.

  ## Example

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          "Payment-ID-0001",
          Date.utc_today() |> Date.add(5),
          "Creditor Name",
          "DE87200500001234567890",
          "BANKDEFFXXX",
          "DE00ZZZ00099999999"
        )
  """
  def add_payment_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = cddi,
        pmt_inf_id,
        %Date{} = reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        dbtr_agt_bic,
        cdtr_id,
        seq_tp \\ :First
      )
      when is_binary(pmt_inf_id) and is_binary(cdtr_nm) and is_binary(cdtr_acct_iban) and
             is_binary(dbtr_agt_bic) and is_binary(cdtr_id) and
             seq_tp in @sequence_type3_code_atom do
    ExSepa.CustomerDirectDebitInitiationV08.add_pmt_inf(
      cddi,
      pmt_inf_id,
      reqd_colltn_dt,
      cdtr_nm,
      cdtr_acct_iban,
      dbtr_agt_bic,
      cdtr_id,
      @sequence_type3_code[seq_tp]
    )
  end

  @doc """
  Transaction Information: Provides information on the individual transaction(s) included in the message.

  ## Example

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Payment-ID-0001",
          "EndToEndId-0001",
          100.01,
          "Mandate-Id-01",
          ~D[2021-01-21],
          "Debtor Name",
          "CH7280005000088877766",
          "RAIFCH22005",
          "Unstructured Remittance Information"
        )
  """
  def add_transaction_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = cddi,
        pmt_inf_id,
        end_to_end_id,
        instd_amt,
        mndt_id,
        %Date{} = dt_of_sgntr,
        dbtr_nm,
        dbtr_acct_iban,
        dbtr_agt_bic \\ "",
        rmt_inf \\ ""
      )
      when is_binary(pmt_inf_id) and is_binary(end_to_end_id) and is_float(instd_amt) and
             is_binary(mndt_id) and is_binary(dbtr_nm) and is_binary(dbtr_acct_iban) and
             is_binary(dbtr_agt_bic) and is_binary(rmt_inf) do
    ExSepa.CustomerDirectDebitInitiationV08.add_drct_dbt_tx_inf(
      cddi,
      pmt_inf_id,
      end_to_end_id,
      instd_amt,
      mndt_id,
      dt_of_sgntr,
      dbtr_nm,
      dbtr_acct_iban,
      dbtr_agt_bic,
      rmt_inf
    )
  end

  @doc false
  def add_transaction_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = cddi,
        pmt_inf_id,
        %ExSepa.TransactionInformation{} = ddti
      )
      when is_binary(pmt_inf_id) do
    %ExSepa.CustomerDirectDebitInitiationV08{cddi | drctDbtTxInf: [{pmt_inf_id, ddti}]}
  end

  @doc """
  Returns the data in the ISO 20022 XML message standard.

  ## Example

      ExSepa.DirectDebit.to_xml(direct_debit)
  """
  def to_xml(%ExSepa.CustomerDirectDebitInitiationV08{} = cddi) do
    ExSepa.CustomerDirectDebitInitiationV08.to_xml(cddi)
  end
end
