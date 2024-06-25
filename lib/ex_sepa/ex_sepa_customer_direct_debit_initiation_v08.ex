defmodule ExSepa.CustomerDirectDebitInitiationV08 do
  import XmlBuilder

  @moduledoc false
  # """
  # # CustomerDirectDebitInitiationV08
  # """

  @enforce_keys [:grpHdr]
  @type t :: %__MODULE__{
          grpHdr: ExSepa.GroupHeader.t(),
          # List of Payment Informations
          pmtInf: list(ExSepa.PaymentInformation.t()),
          # List of Direct Debit Transaction Informations
          drctDbtTxInf: list({String.t(), ExSepa.TransactionInformation.t()})
        }
  defstruct [:grpHdr, :pmtInf, :drctDbtTxInf]

  @doc false
  def new(msg_id, initiation_party) do
    case ExSepa.GroupHeader.new(msg_id, initiation_party) do
      {:ok, grphdr} ->
        %__MODULE__{grpHdr: grphdr}

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  def add_pmt_inf(
        cddi,
        pmt_inf_id,
        reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        dbtr_agt_bic,
        cdtr_id,
        seq_tp \\ "OOFF"
      )

  def add_pmt_inf(
        %__MODULE__{} = cddi,
        pmt_inf_id,
        reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        dbtr_agt_bic,
        cdtr_id,
        seq_tp
      )
      when cddi.pmtInf == nil do
    case ExSepa.PaymentInformation.new(
           pmt_inf_id,
           reqd_colltn_dt,
           cdtr_nm,
           cdtr_acct_iban,
           dbtr_agt_bic,
           cdtr_id,
           seq_tp
         ) do
      {:ok, payment_information} ->
        %__MODULE__{cddi | pmtInf: [payment_information]}

      {:error, e} ->
        {:error, e}
    end
  end

  def add_pmt_inf(
        %__MODULE__{} = cddi,
        pmt_inf_id,
        reqd_colltn_dt,
        cdtr_nm,
        cdtr_acct_iban,
        dbtr_agt_bic,
        cdtr_id,
        seq_tp
      ) do
    case ExSepa.PaymentInformation.new(
           pmt_inf_id,
           reqd_colltn_dt,
           cdtr_nm,
           cdtr_acct_iban,
           dbtr_agt_bic,
           cdtr_id,
           seq_tp
         ) do
      {:ok, payment_information} ->
        %__MODULE__{cddi | pmtInf: [payment_information | cddi.pmtInf]}

      {:error, e} ->
        {:error, e}
    end
  end

  @doc false
  def add_drct_dbt_tx_inf(
        cddi,
        pmt_inf_id,
        end_to_end_id,
        instd_amt,
        mndt_id,
        dt_of_sgntr,
        dbtr_nm,
        dbtr_acct_iban,
        dbtr_agt_bic \\ "",
        rmt_inf \\ ""
      )

  def add_drct_dbt_tx_inf(
        %__MODULE__{} = cddi,
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
      when cddi.drctDbtTxInf == nil do
    %__MODULE__{
      cddi
      | drctDbtTxInf: [
          {
            pmt_inf_id,
            ExSepa.TransactionInformation.new(
              end_to_end_id,
              instd_amt,
              mndt_id,
              dt_of_sgntr,
              dbtr_nm,
              dbtr_acct_iban,
              dbtr_agt_bic,
              rmt_inf
            )
          }
        ]
    }
  end

  def add_drct_dbt_tx_inf(
        %__MODULE__{} = cddi,
        pmt_inf_id,
        end_to_end_id,
        instd_amt,
        mndt_id,
        dt_of_sgntr,
        dbtr_nm,
        dbtr_acct_iban,
        dbtr_agt_bic,
        rmt_inf
      ) do
    %__MODULE__{
      cddi
      | drctDbtTxInf: [
          {
            pmt_inf_id,
            ExSepa.TransactionInformation.new(
              end_to_end_id,
              instd_amt,
              mndt_id,
              dt_of_sgntr,
              dbtr_nm,
              dbtr_acct_iban,
              dbtr_agt_bic,
              rmt_inf
            )
          }
          | cddi.drctDbtTxInf
        ]
    }
  end

  # @doc """
  # creates the container for CustomerDirectDebitInitiationV08
  # """
  @doc false
  def to_xml(%__MODULE__{} = cddi) do
    {info, nb_of_txs, crtl_sum} = do_create_pmt_inf({cddi.pmtInf, 0, 0.0}, cddi.drctDbtTxInf)

    xb_document(
      element(:CstmrDrctDbtInitn, nil, [
        cddi.grpHdr |> ExSepa.GroupHeader.to_xml(nb_of_txs, crtl_sum)
        | info
      ])
    )
  end

  defp do_create_pmt_inf({[], nb_of_txs, crtl_sum}, _), do: {[], nb_of_txs, crtl_sum}

  defp do_create_pmt_inf(
         {[%ExSepa.PaymentInformation{} = first | rest], nb_of_txs, crtl_sum},
         list
       ) do
    drct_dbt_tx_inf = Enum.filter(list, fn {x, _y} -> x == first.pmtInfId end)
    count = length(drct_dbt_tx_inf)

    sum =
      Enum.reduce(drct_dbt_tx_inf, 0, fn {_k, %ExSepa.TransactionInformation{} = v}, acc ->
        v.instdAmt + acc
      end) * 1.0

    {new_rest, new_nb_of_txs, new_crtl_sum} =
      do_create_pmt_inf({rest, nb_of_txs + count, crtl_sum + sum}, list)

    {[
       ExSepa.PaymentInformation.create(
         first,
         ExSepa.TransactionInformation.create(drct_dbt_tx_inf),
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
