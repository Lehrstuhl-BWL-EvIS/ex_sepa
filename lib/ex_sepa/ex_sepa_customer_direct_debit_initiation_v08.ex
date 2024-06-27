defmodule ExSepa.CustomerDirectDebitInitiationV08 do
  import XmlBuilder

  @moduledoc """
  CustomerDirectDebitInitiationV08 (pain.008.001.08)

  The CustomerDirectDebitInitiation message is sent by the initiating party to the forwarding agent or creditor agent.
  It is used to request single or bulk collection(s) of funds from one or various debtor's account(s) for a creditor.
  """

  @enforce_keys [:group_header]
  @type t :: %__MODULE__{
          group_header: ExSepa.GroupHeader.t(),
          payment_information: list(ExSepa.PaymentInformation.t()),
          transaction_information: list({String.t(), ExSepa.TransactionInformation.t()})
        }
  defstruct [:group_header, :payment_information, :transaction_information]

  @doc false
  @spec new(String.t(), String.t()) :: {:error, String.t()} | __MODULE__.t()
  def new(msg_id, direct_debit_party) do
    case ExSepa.GroupHeader.new(msg_id, direct_debit_party) do
      {:ok, group_header} ->
        %__MODULE__{group_header: group_header}

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  @spec add_payment_information(
          ExSepa.CustomerDirectDebitInitiationV08.t(),
          String.t(),
          Date.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          atom()
        ) :: {:error, String.t()} | ExSepa.CustomerDirectDebitInitiationV08.t()
  def add_payment_information(
        direct_debit,
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        debtor_bic \\ "",
        sequence_type \\ :OneOff
      )

  def add_payment_information(
        %__MODULE__{} = direct_debit,
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        debtor_bic,
        sequence_type
      )
      when direct_debit.payment_information == nil do
    case ExSepa.PaymentInformation.new(
           payment_id,
           due_date,
           creditor_id,
           creditor_name,
           creditor_iban,
           debtor_bic,
           sequence_type
         ) do
      {:ok, payment_information} ->
        %__MODULE__{direct_debit | payment_information: [payment_information]}

      {:error, e} ->
        {:error, e}
    end
  end

  def add_payment_information(
        %__MODULE__{} = direct_debit,
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        debtor_bic,
        sequence_type
      ) do
    case Enum.filter(direct_debit.payment_information, &(&1.payment_id == payment_id)) do
      [] ->
        case ExSepa.PaymentInformation.new(
               payment_id,
               due_date,
               creditor_id,
               creditor_name,
               creditor_iban,
               debtor_bic,
               sequence_type
             ) do
          {:ok, payment_information} ->
            %__MODULE__{
              direct_debit
              | payment_information: [payment_information | direct_debit.payment_information]
            }

          {:error, e} ->
            {:error, e}
        end

      _ ->
        {:error, "payment_id: #{payment_id} already exists"}
    end
  end

  @doc false
  def add_transaction_information(
        direct_debit,
        payment_id,
        end_to_end_id,
        amount,
        mandate_id,
        mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic \\ "",
        remittance_information \\ ""
      )

  def add_transaction_information(
        %__MODULE__{} = direct_debit,
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
      when direct_debit.transaction_information == nil do
    case Enum.filter(direct_debit.payment_information, &(&1.payment_id == payment_id)) do
      [] ->
        {:error, "payment_id: #{payment_id} does not exists in payment information"}

      _ ->
        case ExSepa.TransactionInformation.new(
               end_to_end_id,
               amount,
               mandate_id,
               mandate_signing_date,
               debtor_name,
               debtor_iban,
               debtor_bic,
               remittance_information
             ) do
          {:ok, transaction_information} ->
            %__MODULE__{
              direct_debit
              | transaction_information: [{payment_id, transaction_information}]
            }

          {:error, e} ->
            {:error, e}
        end
    end
  end

  def add_transaction_information(
        %__MODULE__{} = direct_debit,
        payment_id,
        end_to_end_id,
        amount,
        mandate_id,
        mandate_signing_date,
        debtor_name,
        debtor_iban,
        debtor_bic,
        remittance_information
      ) do
    case Enum.filter(direct_debit.payment_information, &(&1.payment_id == payment_id)) do
      [] ->
        {:error, "payment_id: #{payment_id} does not exists in payment information"}

      _ ->
        case ExSepa.TransactionInformation.new(
               end_to_end_id,
               amount,
               mandate_id,
               mandate_signing_date,
               debtor_name,
               debtor_iban,
               debtor_bic,
               remittance_information
             ) do
          {:ok, transaction_information} ->
            %__MODULE__{
              direct_debit
              | transaction_information: [
                  {payment_id, transaction_information} | direct_debit.transaction_information
                ]
            }

          {:error, e} ->
            {:error, e}
        end
    end
  end

  @doc false
  @spec to_xml(ExSepa.CustomerDirectDebitInitiationV08.t()) :: String.t()
  def to_xml(%__MODULE__{} = direct_debit) do
    {info, number_of_transactions, control_sum} =
      do_to_xml({direct_debit.payment_information, 0, 0.0}, direct_debit.transaction_information)

    xb_document(
      element(:CstmrDrctDbtInitn, nil, [
        direct_debit.group_header
        |> ExSepa.GroupHeader.to_xml(number_of_transactions, control_sum)
        | info
      ])
    )
  end

  defp do_to_xml({[], number_of_transactions, control_sum}, _),
    do: {[], number_of_transactions, control_sum}

  defp do_to_xml(
         {[%ExSepa.PaymentInformation{} = first | rest], number_of_transactions, control_sum},
         list
       ) do
    transaction_information = Enum.filter(list, fn {x, _y} -> x == first.payment_id end)
    count = length(transaction_information)

    sum =
      Enum.reduce(transaction_information, 0, fn {_k, %ExSepa.TransactionInformation{} = v},
                                                 acc ->
        v.amount + acc
      end) * 1.0

    {new_rest, new_number_of_transactions, new_control_sum} =
      do_to_xml({rest, number_of_transactions + count, control_sum + sum}, list)

    {[
       ExSepa.PaymentInformation.to_xml(
         first,
         ExSepa.TransactionInformation.to_xml(transaction_information),
         count,
         sum
       )
       | new_rest
     ], new_number_of_transactions, new_control_sum}
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
end
