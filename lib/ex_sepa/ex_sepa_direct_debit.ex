defmodule ExSepa.DirectDebit do
  @moduledoc """
  Documentation for `ExSepa.DirectDebit`.

  This library is based on the structure of the SEPA Core Direct Debit Scheme.
  The direct debit initiation message is sent by the initiating party to the creditor's intermediary or agent.
  It is used to request a single or batch collection(s) of funds from one or more debtor accounts on behalf of a creditor.

  ## Example

      # 1) Create a new direct debit initiation message.
      direct_debit = ExSepa.DirectDebit.new(
      %{"msg_id" => "Msg-ID-001", "initiating_party_name" => "Initiating Party",
        "payment_information" => [%{"payment_id" => "Payment-ID-0001",
          "due_date" => %Date{} = Date.utc_today() |> Date.add(5),
          "creditor_id" => "DE00ZZZ00099999999",
          "creditor_name" => "Creditor Name",
          "creditor_iban" => "DE87200500001234567890",
          "transaction_information" => [%{"end_to_end_id" => "EndToEndId-0001",
            "amount" => 100.01,
            "mandate_id" => "Mandate-Id-01",
            "mandate_signing_date" => ~D[2021-01-21],
            "debtor_name" => "Debtor Name",
            "debtor_iban" => "CH7280005000088877766"}]
            }]
        })

      # 2) Receive the SEPA compliant XML message as a string.
      ExSepa.DirectDebit.to_xml(direct_debit)
  """

  @doc """
  Creates a new Direct Debit with a `Unique Message Id` and `Initiating Party Name`.

  The map has to contain the following keys:
    * `"msg_id"`
    * `"initiating_party_name"`
  """
  @spec new(map()) :: {:error, String.t()} | ExSepa.CustomerDirectDebitInitiationV08.t()
  def new(group_header), do: ExSepa.CustomerDirectDebitInitiationV08.new(group_header)

  @doc """
  Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.
  """
  @spec add_payment_information(
          ExSepa.CustomerDirectDebitInitiationV08.t(),
          map()
        ) :: ExSepa.CustomerDirectDebitInitiationV08.t() | {:error, String.t()}
  def add_payment_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = initiation,
        payment_information
      )
      when is_map(payment_information) do
    ExSepa.CustomerDirectDebitInitiationV08.add_payment_information(
      initiation,
      payment_information
    )
  end

  @doc """
  Transaction Information: Provides information on the individual transaction(s) included in the message.
  """
  @spec add_transaction_information(
          ExSepa.CustomerDirectDebitInitiationV08.t(),
          String.t(),
          map()
        ) :: ExSepa.CustomerDirectDebitInitiationV08.t()
  def add_transaction_information(
        %ExSepa.CustomerDirectDebitInitiationV08{} = initiation,
        payment_id,
        transaction_information
      )
      when is_binary(payment_id) and is_map(transaction_information) do
    ExSepa.CustomerDirectDebitInitiationV08.add_transaction_information(
      initiation,
      payment_id,
      transaction_information
    )
  end

  @spec to_xml(ExSepa.CustomerDirectDebitInitiationV08.t()) :: String.t()
  @doc """
  Returns the data in the ISO 20022 XML message standard.
  """
  def to_xml(%ExSepa.CustomerDirectDebitInitiationV08{} = initiation) do
    ExSepa.CustomerDirectDebitInitiationV08.to_xml(initiation)
  end
end
