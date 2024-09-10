defmodule ExSepa.PaymentInformation do
  alias ExSepa.Validation

  @moduledoc false
  # """
  # Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.
  # """

  @type sequence_type3_code_atom :: :OneOff | :First | :Recurring | :Final
  @sequence_type3_code_atom [:OneOff, :First, :Recurring, :Final]
  @sequence_type3_code %{OneOff: "OOFF", First: "FRST", Recurring: "RCUR", Final: "FNAL"}

  @enforce_keys [:payment_id, :due_date, :creditor_id, :creditor_name, :creditor_iban]
  @typedoc false
  @type t :: %__MODULE__{
          payment_id: String.t(),
          due_date: Date.t(),
          creditor_id: String.t(),
          creditor_name: String.t(),
          creditor_address: ExSepa.Address.t() | nil,
          creditor_iban: String.t(),
          creditor_bic: String.t(),
          sequence_type: sequence_type3_code_atom(),
          transaction_information: list(ExSepa.TransactionInformation.t()) | nil
        }

  defstruct [
    :payment_id,
    :due_date,
    :creditor_id,
    :creditor_name,
    :creditor_address,
    :creditor_iban,
    creditor_bic: "",
    sequence_type: :OneOff,
    transaction_information: []
  ]

  @doc false
  # """
  # Add Payment Information: Set of characteristics that apply to the credit side of the payment transactions included in the direct debit transaction initiation.

  # The map has the following keys:

  #   * `:payment_id` - Unique identification, as assigned by a sending party, to unambiguously identify the payment information group within the message (maximum length of 35 characters).
  #   * `:due_date` - The Due Date of the Collection (ISODate).
  #   * `:creditor_id` - Unique and unambiguous identification of a party (maximum length of 35 characters.).
  #   * `:creditor_name` - The Name of the Creditor (maximum length of 70 characters).
  #   * `:creditor_iban` - The account number (IBAN) of the Creditor.
  #   * `:creditor_bic` - OPTIONAL: BIC code of the Creditor PSP.
  #   * `:sequence_type` - OPTIONAL: Identifies the direct debit sequence, such as one-off, first, recurrent or final ("OOFF", "FRST", "RCUR" or "FNAL").
  #   * `:creditor_address` - OPTIONAL: Structured address. At least `:town_name` and `:country` must be used. More details in `ExSepa.Address`.
  # """
  @spec new(%{
          :payment_id => String.t(),
          :due_date => any(),
          :creditor_id => String.t(),
          :creditor_name => String.t(),
          :creditor_iban => String.t(),
          optional(atom()) => any()
        }) :: {:error, String.t()} | {:ok, __MODULE__.t()}
  def new(
        %{
          payment_id: payment_id,
          due_date: %Date{} = due_date,
          creditor_id: creditor_id,
          creditor_name: creditor_name,
          creditor_iban: creditor_iban
        } = payment_information
      )
      when is_binary(payment_id) and is_binary(creditor_id) and
             is_binary(creditor_name) and is_binary(creditor_iban) do
    with {:ok, new_payment_id} <- Validation.max_text(:payment_id, payment_id, 35),
         :ok <- Validation.due_date(due_date),
         {:ok, new_creditor_id} <- Validation.max_text(:creditor_id, creditor_id, 35),
         {:ok, new_creditor_name} <- Validation.max_text(:creditor_name, creditor_name, 70),
         :ok <- Validation.iban(creditor_iban),
         {:ok, optional_data} <- get_optional_data(payment_information) do
      {:ok,
       %__MODULE__{
         payment_id: new_payment_id,
         due_date: due_date,
         creditor_id: new_creditor_id,
         creditor_name: new_creditor_name,
         creditor_iban: creditor_iban,
         creditor_bic: optional_data.creditor_bic,
         sequence_type: optional_data.sequence_type,
         transaction_information: optional_data.transaction_information,
         creditor_address: optional_data.creditor_address
       }}
    end
  end

  def new(
        %{
          payment_id: payment_id,
          due_date: _due_date,
          creditor_id: creditor_id,
          creditor_name: creditor_name,
          creditor_iban: creditor_iban
        } = _payment_information
      )
      when is_binary(payment_id) and is_binary(creditor_id) and
             is_binary(creditor_name) and is_binary(creditor_iban) do
    {:error, "Parameter due_date must be a date"}
  end

  def new(payment_information) do
    missing_keys = @enforce_keys -- Map.keys(payment_information)

    if missing_keys == [] do
      with :ok <-
             Validation.text(
               [
                 {:payment_id, payment_information[:payment_id]},
                 {:creditor_id, payment_information[:creditor_id]},
                 {:creditor_name, payment_information[:creditor_name]},
                 {:creditor_iban, payment_information[:creditor_iban]}
               ],
               "Parameters must be strings."
             ) do
        {:error, "Something has gone wrong: #{payment_information}"}
      end
    else
      {:error, "missing keys: " <> Macro.to_string(quote do: unquote(missing_keys))}
    end
  end

  defp get_optional_data(payment_information) do
    with {:ok, creditor_bic} <- get_creditor_bic(payment_information),
         {:ok, sequence_type} <- get_sequence_type(payment_information),
         {:ok, transaction_information} <- get_transaction_information(payment_information),
         {:ok, creditor_address} <-
           ExSepa.Address.get_address(payment_information, :creditor_address),
         :ok <- Validation.bic(creditor_bic) do
      {:ok,
       %{
         creditor_bic: creditor_bic,
         sequence_type: sequence_type,
         transaction_information: transaction_information,
         creditor_address: creditor_address
       }}
    end
  end

  defp get_creditor_bic(payment_information) do
    case Map.fetch(payment_information, :creditor_bic) do
      {:ok, creditor_bic} when is_binary(creditor_bic) ->
        {:ok, creditor_bic}

      {:ok, creditor_bic} ->
        Validation.text([{:creditor_bic, creditor_bic}], "Parameters must be strings.")

      :error ->
        {:ok, ""}
    end
  end

  defp get_sequence_type(payment_information) do
    case Map.fetch(payment_information, :sequence_type) do
      {:ok, sequence_type} ->
        if sequence_type in @sequence_type3_code_atom,
          do: {:ok, sequence_type},
          else:
            {:error,
             "Parameter sequence_type must be an atom :#{Enum.join(@sequence_type3_code_atom, ", :")}"}

      :error ->
        {:ok, List.first(@sequence_type3_code_atom)}
    end
  end

  defp get_transaction_information(payment_information) do
    case Map.fetch(payment_information, :transaction_information) do
      {:ok, transaction_information} when is_list(transaction_information) ->
        {:ok, transaction_information}

      :error ->
        {:ok, []}
    end
  end

  @doc false
  # """
  # Converts the sequence type into the corresponding code.
  # """
  def get_sequenz_type_code(sequence_type) do
    @sequence_type3_code[sequence_type]
  end
end

defmodule ExSepa.PaymentInformationError do
  @moduledoc false
  defexception [:message]
end
