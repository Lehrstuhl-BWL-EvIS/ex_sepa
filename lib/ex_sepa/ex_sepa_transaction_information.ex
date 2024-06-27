defmodule ExSepa.TransactionInformation do
  import XmlBuilder

  @moduledoc """
  Direct Debit Transaction Information: Provides information on the individual transaction(s) included in the message.
  """
  alias ExSepa.Validation

  @enforce_keys [
    :end_to_end_id,
    :amount,
    :mandate_id,
    :mandate_signing_date,
    :debtor_name,
    :debtor_iban
  ]
  @typedoc """
  The map has the following keys:

    * `:end_to_end_id` - The Creditor's Reference of the Direct Debit Transaction (maximum length of 35 characters).
    * `:amount` - The Amount of the Collection in euro.
    * `:mandate_id` - The Unique Mandate Reference (maximum length of 35 characters).
    * `:mandate_signing_date` - The Date of Signing of the Mandate (ISODate).
    * `:debtor_name` - The Name of the Debtor (maximum length of 70 characters).
    * `:debtor_iban` - The account number (IBAN) of the Debtor.
    * `:debtor_bic` - BIC code of the Debtor PSP.
    * `:remittance_information` - The Remittance information sent by the Creditor to the Debtor in the Collection (maximum length of 140 characters).
  """
  defstruct [
    :end_to_end_id,
    :amount,
    :mandate_id,
    :mandate_signing_date,
    :debtor_name,
    :debtor_iban,
    debtor_bic: "",
    remittance_information: ""
  ]

  @type t :: %__MODULE__{
          end_to_end_id: String.t(),
          amount: float(),
          mandate_id: String.t(),
          mandate_signing_date: Date.t(),
          debtor_name: String.t(),
          debtor_iban: String.t(),
          debtor_bic: String.t(),
          remittance_information: String.t()
        }

  @spec new(
          String.t(),
          float(),
          String.t(),
          Date.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) ::
          {:error, String.t()} | {:ok, ExSepa.TransactionInformation.t()}

  @doc false
  def new(
        end_to_end_id,
        amount,
        mandate_id,
        mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic \\ "",
        remittance_information \\ ""
      )

  def new(
        end_to_end_id,
        amount,
        mandate_id,
        %Date{} = mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic,
        remittance_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) and is_binary(debtor_bic) and
             is_binary(remittance_information) do
    with :ok <- Validation.max_text(:end_to_end_id, end_to_end_id, 35),
         :ok <- Validation.amount(amount),
         :ok <- Validation.max_text(:mandate_id, mandate_id, 35),
         :ok <- Validation.date(mandate_signing_date),
         :ok <- Validation.max_text(:debtor_name, debtor_name, 70),
         :ok <- Validation.iban(debtor_iban),
         :ok <- Validation.bic(debtor_bic),
         :ok <- Validation.max_text(:remittance_information, remittance_information, 140) do
      {:ok,
       %__MODULE__{
         end_to_end_id: end_to_end_id,
         amount: amount,
         mandate_id: mandate_id,
         mandate_signing_date: mandate_signing_date,
         debtor_name: debtor_name,
         debtor_iban: debtor_iban,
         debtor_bic: debtor_bic,
         remittance_information: remittance_information
       }}
    else
      {:error, e} -> {:error, e}
    end
  end

  def new(
        end_to_end_id,
        amount,
        mandate_id,
        _mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic,
        remittance_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) and is_binary(debtor_bic) and
             is_binary(remittance_information) do
    {:error, "mandate_signing_date must be a date"}
  end

  def new(
        end_to_end_id,
        _amount,
        mandate_id,
        _mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic,
        remittance_information
      )
      when is_binary(end_to_end_id) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) and is_binary(debtor_bic) and
             is_binary(remittance_information) do
    {:error, "amount must be a float(18.2)"}
  end

  def new(
        end_to_end_id,
        _amount,
        mandate_id,
        _mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic,
        remittance_information
      ) do
    Validation.text(
      [
        {:end_to_end_id, end_to_end_id},
        {:mandate_id, mandate_id},
        {:debtor_name, debtor_name},
        {:debtor_iban, debtor_iban},
        {:debtor_bic, debtor_bic},
        {:remittance_information, remittance_information}
      ],
      "Parameters must be strings."
    )
  end

  @doc false
  @spec to_xml([{any(), __MODULE__.t()}]) :: list()
  def to_xml([]), do: []

  def to_xml([{_, %__MODULE__{} = first} | rest]) do
    [do_to_xml(first) | to_xml(rest)]
  end

  defp do_to_xml(%__MODULE__{} = transaction_information) do
    element(:DrctDbtTxInf, nil, [
      element(:PmtId, nil, [
        element(:EndToEndId, nil, transaction_information.end_to_end_id)
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
          if transaction_information.debtor_bic == "" do
            element(:Othr, nil, [
              element(:Id, nil, "NOTPROVIDED")
            ])
          else
            element(:BICFI, nil, transaction_information.debtor_bic)
          end
        ])
      ]),
      element(:Dbtr, nil, [
        element(:Nm, nil, transaction_information.debtor_name)
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
end
