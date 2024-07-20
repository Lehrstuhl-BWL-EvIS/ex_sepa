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
          payment_information: list(ExSepa.PaymentInformation.t())
        }
  defstruct [:group_header, :payment_information]

  @doc false
  def new(group_header_map) do
    case ExSepa.GroupHeader.new(group_header_map) do
      {:ok, group_header} ->
        %__MODULE__{group_header: group_header}

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  def add_payment_information(%__MODULE__{} = direct_debit, payment_information) do
    case ExSepa.PaymentInformation.new(payment_information) do
      {:ok, ok_payment_information} ->
        if direct_debit.payment_information == nil do
          %__MODULE__{direct_debit | payment_information: [ok_payment_information]}
        else
          case Enum.filter(
                 direct_debit.payment_information,
                 &(&1.payment_id == ok_payment_information.payment_id)
               ) do
            [] ->
              %__MODULE__{
                direct_debit
                | payment_information: [ok_payment_information | direct_debit.payment_information]
              }

            _ ->
              {:error, "payment_id: #{ok_payment_information.payment_id} already exists"}
          end
        end

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  def add_transaction_information(
        %__MODULE__{} = direct_debit,
        payment_id,
        transaction_information
      ) do
    case Enum.filter(direct_debit.payment_information, &(&1.payment_id == payment_id)) do
      [] ->
        {:error, "payment_id: #{payment_id} does not exists in payment information"}

      _ ->
        case ExSepa.TransactionInformation.new(transaction_information) do
          {:ok, ok_transaction_information} ->
            %__MODULE__{
              direct_debit
              | payment_information:
                  find_pmtinf2(
                    direct_debit.payment_information,
                    payment_id,
                    ok_transaction_information
                  )
            }

          {:error, e} ->
            {:error, e}
        end
    end
  end

  defp find_pmtinf2(list, pmtInfId, txinf, acc \\ [])
  defp find_pmtinf2([], _pmtInfId, _txinf, acc), do: acc

  defp find_pmtinf2([%ExSepa.PaymentInformation{} = first | rest], pmtInfId, txinf, acc) do
    find_pmtinf2(rest, pmtInfId, txinf, [
      if first.payment_id == pmtInfId do
        %ExSepa.PaymentInformation{
          first
          | transaction_information:
              if(first.transaction_information == nil,
                do: [txinf],
                else: [txinf | first.transaction_information]
              )
        }
      else
        first
      end
      | acc
    ])
  end

  @doc false
  @spec to_xml(__MODULE__.t()) :: String.t()
  def to_xml(%__MODULE__{} = direct_debit) do
    {info, number_of_transactions, control_sum} =
      do_to_xml({direct_debit.payment_information, 0, 0.0})

    xb_document(
      element(:CstmrDrctDbtInitn, nil, [
        direct_debit.group_header
        |> ExSepa.GroupHeader.to_xml(number_of_transactions, control_sum)
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
        Enum.reduce(first.transaction_information, 0, fn %ExSepa.TransactionInformation{} = v,
                                                         acc ->
          v.amount + acc
        end) * 1.0

      {new_rest, new_number_of_transactions, new_control_sum} =
        do_to_xml({rest, number_of_transactions + count, control_sum + sum})

      {[
         ExSepa.PaymentInformation.to_xml(
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
end
