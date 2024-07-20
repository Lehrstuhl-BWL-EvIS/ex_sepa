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

  @doc false
  @spec new(map()) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{
          "end_to_end_id" => end_to_end_id,
          "amount" => amount,
          "mandate_id" => mandate_id,
          "mandate_signing_date" => %Date{} = mandate_signing_date,
          "debtor_name" => debtor_name,
          "debtor_iban" => debtor_iban
        } = transaction_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    with :ok <- Validation.max_35_text(:end_to_end_id, end_to_end_id),
         :ok <- Validation.amount(amount),
         :ok <- Validation.max_35_text(:mandate_id, mandate_id),
         :ok <- Validation.date(mandate_signing_date),
         :ok <- Validation.max_70_text(:debtor_name, debtor_name),
         :ok <- Validation.iban(debtor_iban),
         {:ok, optional_data} <- get_optional_data(transaction_information) do
      {:ok,
       %__MODULE__{
         end_to_end_id: end_to_end_id,
         amount: amount,
         mandate_id: mandate_id,
         mandate_signing_date: mandate_signing_date,
         debtor_name: debtor_name,
         debtor_iban: debtor_iban,
         debtor_bic: optional_data.debtor_bic,
         remittance_information: optional_data.remittance_information
       }}
    end
  end

  def new(
        %{
          "end_to_end_id" => end_to_end_id,
          "amount" => amount,
          "mandate_id" => mandate_id,
          "mandate_signing_date" => _mandate_signing_date,
          "debtor_name" => debtor_name,
          "debtor_iban" => debtor_iban
        } = _transaction_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "mandate_signing_date must be a date"}
  end

  def new(
        %{
          "end_to_end_id" => end_to_end_id,
          "amount" => _amount,
          "mandate_id" => mandate_id,
          "mandate_signing_date" => _mandate_signing_date,
          "debtor_name" => debtor_name,
          "debtor_iban" => debtor_iban
        } = _transaction_information
      )
      when is_binary(end_to_end_id) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "amount must be a float(18.2)"}
  end

  def new(
        %{
          "end_to_end_id" => end_to_end_id,
          "amount" => _amount,
          "mandate_id" => mandate_id,
          "mandate_signing_date" => _mandate_signing_date,
          "debtor_name" => debtor_name,
          "debtor_iban" => debtor_iban
        } = _transaction_information
      ) do
    Validation.text(
      [
        {:end_to_end_id, end_to_end_id},
        {:mandate_id, mandate_id},
        {:debtor_name, debtor_name},
        {:debtor_iban, debtor_iban}
      ],
      "Parameters must be strings."
    )
  end

  defp get_optional_data(transaction_information) do
    with {:ok, debtor_bic} <- get_creditor_bic(transaction_information),
         {:ok, remittance_information} <- get_remittance_information(transaction_information),
         :ok <- Validation.bic(debtor_bic),
         :ok <- Validation.optional_max_140_text(:remittance_information, remittance_information) do
      {:ok,
       %{
         debtor_bic: debtor_bic,
         remittance_information: remittance_information
       }}
    end
  end

  defp get_creditor_bic(transaction_information) do
    case Map.fetch(transaction_information, "debtor_bic") do
      {:ok, debtor_bic} when is_binary(debtor_bic) ->
        {:ok, debtor_bic}

      {:ok, debtor_bic} ->
        Validation.text([{:debtor_bic, debtor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_remittance_information(transaction_information) do
    case Map.fetch(transaction_information, "remittance_information") do
      {:ok, remittance_information} when is_binary(remittance_information) ->
        {:ok, remittance_information}

      {:ok, remittance_information} ->
        Validation.text(
          [{:remittance_information, remittance_information}],
          "Parameters must be strings."
        )

      :error ->
        {:ok, ""}
    end
  end

  @doc false
  @spec to_xml([__MODULE__.t()]) :: list()
  def to_xml([]), do: []

  def to_xml([%__MODULE__{} = first | rest]) do
    [do_to_xml(first) | to_xml(rest)]
  end

  defp do_to_xml(%__MODULE__{} = transaction_information) do
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
