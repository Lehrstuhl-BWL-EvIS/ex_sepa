defmodule ExSepa.DirectDebit do
  @moduledoc """
  Documentation for `ExSepa.DirectDebit`.

  This library is based on the structure of the SEPA Core Direct Debit Scheme.
  The direct debit initiation message is sent by the initiating party to the creditor's intermediary or agent.
  It is used to request a single or batch collection(s) of funds from one or more debtor accounts on behalf of a creditor.

  ## Example

      # 1) Create a new direct debit initiation message.
      direct_debit = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")

      # 2) Add at least one payment information.
      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          "Payment-ID-0001",
          Date.utc_today() |> Date.add(5),
          "DE00ZZZ00099999999",
          "Creditor Name",
          "DE87200500001234567890",
          "BANKDEFFXXX"
        )

      # 3) Add at least one transaction information to each payment information.
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

      # 4) Receive the SEPA compliant XML message as a string.
      ExSepa.DirectDebit.to_xml(direct_debit)
  """

  # Identifies the direct debit sequence, such as first, recurrent, final or one-off.
  @sequence_type3_code_atom [:OneOff, :First, :Recurring, :Final]

  @doc """
  Creates a new Direct Debit with a `Unique Message Id` and `Initiating Party Name`.
  """
  @spec new(String.t(), String.t()) ::
          {:error, String.t()} | ExSepa.CustomerDirectDebitInitiationV08.t()
  def new(msg_id, initiating_party) do
    ExSepa.CustomerDirectDebitInitiationV08.new(msg_id, initiating_party)
  end

  @doc """
  Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.
  """
  @spec add_payment_information(
          ExSepa.CustomerDirectDebitInitiationV08.t(),
          String.t(),
          Date.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom()
        ) ::
          {:error, String.t()}
          | ExSepa.CustomerDirectDebitInitiationV08.t()
  def add_payment_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = initiation,
        payment_id,
        %Date{} = due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        creditor_bic \\ "",
        sequence_type \\ :OneOff
      )
      when is_binary(payment_id) and is_binary(creditor_name) and is_binary(creditor_iban) and
             is_binary(creditor_bic) and is_binary(creditor_id) and
             sequence_type in @sequence_type3_code_atom do
    ExSepa.CustomerDirectDebitInitiationV08.add_payment_information(
      initiation,
      payment_id,
      due_date,
      creditor_id,
      creditor_name,
      creditor_iban,
      creditor_bic,
      sequence_type
    )
  end

  @doc """
  Transaction Information: Provides information on the individual transaction(s) included in the message.
  """
  @spec add_transaction_information(
          ExSepa.CustomerDirectDebitInitiationV08.t(),
          String.t(),
          String.t(),
          float(),
          String.t(),
          Date.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: ExSepa.CustomerDirectDebitInitiationV08.t()
  def add_transaction_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = initiation,
        payment_id,
        end_to_end_id,
        amount,
        mandate_id,
        %Date{} = mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic \\ "",
        remittance_information \\ ""
      )
      when is_binary(payment_id) and is_binary(end_to_end_id) and is_float(amount) and
             is_binary(mandate_id) and is_binary(debtor_name) and is_binary(debtor_iban) and
             is_binary(debtor_bic) and is_binary(remittance_information) do
    ExSepa.CustomerDirectDebitInitiationV08.add_transaction_information(
      initiation,
      payment_id,
      end_to_end_id,
      amount,
      mandate_id,
      mandate_signing_date,
      debtor_name,
      debtor_iban,
      debtor_bic,
      remittance_information
    )
  end

  @doc false
  def add_transaction_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = initiation,
        payment_id,
        %ExSepa.TransactionInformation{} = transaction_information
      )
      when is_binary(payment_id) do
    %ExSepa.CustomerDirectDebitInitiationV08{
      initiation
      | transaction_information: [{payment_id, transaction_information}]
    }
  end

  @doc """
  Returns the data in the ISO 20022 XML message standard.
  """
  def to_xml(%ExSepa.CustomerDirectDebitInitiationV08{} = initiation) do
    ExSepa.CustomerDirectDebitInitiationV08.to_xml(initiation)
  end
end
