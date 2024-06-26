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
  @spec new(String.t(), String.t()) :: {:error, String.t()} | {:ok, struct()}
  def new(msg_id, initiation_party) do
    case ExSepa.GroupHeader.new(msg_id, initiation_party) do
      {:ok, group_header} ->
        %__MODULE__{group_header: group_header}

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  def add_payment_information(
        initiation,
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        debtor_bic \\ "",
        sequence_type \\ "OOFF"
      )

  def add_payment_information(
        %__MODULE__{} = initiation,
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        debtor_bic,
        sequence_type
      )
      when initiation.payment_information == nil do
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
        %__MODULE__{initiation | payment_information: [payment_information]}

      {:error, e} ->
        {:error, e}
    end
  end

  def add_payment_information(
        %__MODULE__{} = initiation,
        payment_id,
        due_date,
        creditor_id,
        creditor_name,
        creditor_iban,
        debtor_bic,
        sequence_type
      ) do
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
          initiation
          | payment_information: [payment_information | initiation.payment_information]
        }

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  def add_transaction_information(
        initiation,
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
        %__MODULE__{} = initiation,
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
      when initiation.transaction_information == nil do
    %__MODULE__{
      initiation
      | transaction_information: [
          {
            payment_id,
            ExSepa.TransactionInformation.new(
              end_to_end_id,
              amount,
              mandate_id,
              mandate_signing_date,
              debtor_name,
              debtor_iban,
              debtor_bic,
              remittance_information
            )
          }
        ]
    }
  end

  def add_transaction_information(
        %__MODULE__{} = initiation,
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
    %__MODULE__{
      initiation
      | transaction_information: [
          {
            payment_id,
            ExSepa.TransactionInformation.new(
              end_to_end_id,
              amount,
              mandate_id,
              mandate_signing_date,
              debtor_name,
              debtor_iban,
              debtor_bic,
              remittance_information
            )
          }
          | initiation.transaction_information
        ]
    }
  end

  @doc false
  def to_xml(%__MODULE__{} = initiation) do
    {info, nb_of_txs, crtl_sum} =
      do_to_xml({initiation.payment_information, 0, 0.0}, initiation.transaction_information)

    xb_document(
      element(:CstmrDrctDbtInitn, nil, [
        initiation.group_header |> ExSepa.GroupHeader.to_xml(nb_of_txs, crtl_sum)
        | info
      ])
    )
  end

  defp do_to_xml({[], nb_of_txs, crtl_sum}, _), do: {[], nb_of_txs, crtl_sum}

  defp do_to_xml(
         {[%ExSepa.PaymentInformation{} = first | rest], nb_of_txs, crtl_sum},
         list
       ) do
    drct_dbt_tx_inf = Enum.filter(list, fn {x, _y} -> x == first.payment_id end)
    count = length(drct_dbt_tx_inf)

    sum =
      Enum.reduce(drct_dbt_tx_inf, 0, fn {_k, %ExSepa.TransactionInformation{} = v}, acc ->
        v.amount + acc
      end) * 1.0

    {new_rest, new_nb_of_txs, new_crtl_sum} =
      do_to_xml({rest, nb_of_txs + count, crtl_sum + sum}, list)

    {[
       ExSepa.PaymentInformation.to_xml(
         first,
         ExSepa.TransactionInformation.to_xml(drct_dbt_tx_inf),
         count,
         sum
       )
       | new_rest
     ], new_nb_of_txs, new_crtl_sum}
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
