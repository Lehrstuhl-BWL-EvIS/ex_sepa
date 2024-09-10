defmodule ExSepa.TransactionInformation do
  @moduledoc false
  # """
  # Direct Debit Transaction Information: Provides information on the individual transaction(s) included in the message.
  # """
  alias ExSepa.Validation

  @enforce_keys [
    :end_to_end_id,
    :amount,
    :mandate_id,
    :mandate_signing_date,
    :debtor_name,
    :debtor_iban
  ]
  @typedoc false
  @type t :: %__MODULE__{
          end_to_end_id: String.t(),
          amount: float(),
          mandate_id: String.t(),
          mandate_signing_date: Date.t(),
          debtor_name: String.t(),
          debtor_address: ExSepa.Address.t() | nil,
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
    :debtor_address,
    :debtor_iban,
    debtor_bic: "",
    remittance_information: ""
  ]

  @doc false
  # """
  # Add Transaction Information: Provides information on the individual transaction included in the message.

  # The map has the following keys:

  #   * `:end_to_end_id` - The Creditor's Reference of the Direct Debit Transaction (maximum length of 35 characters).
  #   * `:amount` - The Amount of the Collection in euro.
  #   * `:mandate_id` - The Unique Mandate Reference (maximum length of 35 characters).
  #   * `:mandate_signing_date` - The Date of Signing of the Mandate (ISODate).
  #   * `:debtor_name` - The Name of the Debtor (maximum length of 70 characters).
  #   * `:debtor_iban` - The account number (IBAN) of the Debtor.
  #   * `:debtor_bic` - OPTIONAL: BIC code of the Debtor PSP. Only mandatory when the Creditor PSP or the Debtor PSP is located in a non-EEA SEPA country or territory.
  #   * `:debtor_address` - OPTIONAL: Structured address. Only mandatory when the Creditor PSP or the Debtor PSP is located in a non-EEA SEPA country or territory. At least `:town_name` and `:country` must be used. More details in `ExSepa.Address`.
  #   * `:remittance_information` - OPTIONAL: The Remittance information sent by the Creditor to the Debtor in the Collection (maximum length of 140 characters).
  # """
  @spec new(%{
          :end_to_end_id => binary(),
          :amount => float(),
          :mandate_id => binary(),
          :mandate_signing_date => Date.t(),
          :debtor_name => binary(),
          :debtor_iban => binary(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{
          end_to_end_id: end_to_end_id,
          amount: amount,
          mandate_id: mandate_id,
          mandate_signing_date: %Date{} = mandate_signing_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = transaction_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    with {:ok, new_end_to_end_id} <- Validation.max_text(:end_to_end_id, end_to_end_id, 35),
         :ok <- Validation.amount(amount),
         {:ok, new_mandate_id} <- Validation.max_text(:mandate_id, mandate_id, 35),
         :ok <- Validation.date(mandate_signing_date),
         {:ok, new_debtor_name} <- Validation.max_text(:debtor_name, debtor_name, 70),
         :ok <- Validation.iban(debtor_iban),
         {:ok, optional_data} <- get_optional_data(transaction_information),
         :ok <-
           Validation.address_mandatory(
             String.slice(debtor_iban, 0, 2),
             optional_data.debtor_bic,
             optional_data.debtor_address
           ) do
      {:ok,
       %__MODULE__{
         end_to_end_id: new_end_to_end_id,
         amount: amount,
         mandate_id: new_mandate_id,
         mandate_signing_date: mandate_signing_date,
         debtor_name: new_debtor_name,
         debtor_iban: debtor_iban,
         debtor_bic: optional_data.debtor_bic,
         remittance_information: optional_data.remittance_information,
         debtor_address: optional_data.debtor_address
       }}
    end
  end

  def new(
        %{
          end_to_end_id: end_to_end_id,
          amount: amount,
          mandate_id: mandate_id,
          mandate_signing_date: _mandate_signing_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = _transaction_information
      )
      when is_binary(end_to_end_id) and is_float(amount) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "mandate_signing_date must be a date"}
  end

  def new(
        %{
          end_to_end_id: end_to_end_id,
          amount: _amount,
          mandate_id: mandate_id,
          mandate_signing_date: _mandate_signing_date,
          debtor_name: debtor_name,
          debtor_iban: debtor_iban
        } = _transaction_information
      )
      when is_binary(end_to_end_id) and is_binary(mandate_id) and
             is_binary(debtor_name) and is_binary(debtor_iban) do
    {:error, "amount must be a float(18.2)"}
  end

  def new(transaction_information) do
    missing_keys = @enforce_keys -- Map.keys(transaction_information)

    if missing_keys == [] do
      with :ok <-
             Validation.text(
               [
                 {:end_to_end_id, transaction_information[:end_to_end_id]},
                 {:mandate_id, transaction_information[:mandate_id]},
                 {:debtor_name, transaction_information[:debtor_name]},
                 {:debtor_iban, transaction_information[:debtor_iban]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{transaction_information}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  defp get_optional_data(transaction_information) do
    with {:ok, debtor_bic} <- get_creditor_bic(transaction_information),
         {:ok, remittance_information} <- get_remittance_information(transaction_information),
         {:ok, debtor_address} <-
           ExSepa.Address.get_address(transaction_information, :debtor_address),
         :ok <- Validation.bic(debtor_bic),
         {:ok, new_remittance_information} <-
           Validation.optional_max_text(:remittance_information, remittance_information, 140) do
      {:ok,
       %{
         debtor_bic: debtor_bic,
         remittance_information: new_remittance_information,
         debtor_address: debtor_address
       }}
    end
  end

  defp get_creditor_bic(transaction_information) do
    case Map.fetch(transaction_information, :debtor_bic) do
      {:ok, debtor_bic} when is_binary(debtor_bic) ->
        {:ok, debtor_bic}

      {:ok, debtor_bic} ->
        Validation.text([{:debtor_bic, debtor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_remittance_information(transaction_information) do
    case Map.fetch(transaction_information, :remittance_information) do
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
end

defmodule ExSepa.TransactionInformationError do
  @moduledoc false
  defexception [:message]
end
