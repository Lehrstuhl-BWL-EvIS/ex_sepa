defmodule ExSepa.TransactionInformation do
  import XmlBuilder

  @moduledoc false
  # """
  # # Direct Debit Transaction Information
  # """

  @enforce_keys [:endToEndId, :instdAmt, :mndtId, :dtOfSgntr, :dbtrNm, :dbtrAcctIban]
  defstruct [
    :endToEndId,
    :instdAmt,
    :mndtId,
    :dtOfSgntr,
    :dbtrNm,
    :dbtrAcctIban,
    dbtrAgtBic: nil,
    rmtInf: nil
  ]

  @type t :: %__MODULE__{
          endToEndId: String.t(),
          instdAmt: float(),
          mndtId: String.t(),
          dtOfSgntr: Date.t(),
          dbtrNm: String.t(),
          dbtrAcctIban: String.t(),
          dbtrAgtBic: String.t() | nil,
          rmtInf: String.t() | nil
        }

  @doc """
  # new Direct Debit Transaction Information

  endToEndId: Unique identification assigned by the initiating party to unambiguously identify the transaction. This identification is passed on, unchanged, throughout the entire end-to-end chain. Usage: The end-to-end identification can be used for reconciliation or to link tasks relating to the transaction. It can be included in several messages related to the transaction.

  instdAmt: Amount of money to be moved between the debtor and creditor, before deduction of charges, expressed in the currency as ordered by the initiating party. Usage: This amount has to be transported unchanged through the transaction chain. Amount must be 0.01 or more and 999999999.99 or less.

  mndtId: Unique identification, as assigned by the creditor, to unambiguously identify the mandate.

  dtOfSgntr: Date on which the direct debit mandate has been signed by the debtor.

  dbtrAgtBic: BIC code of the Debtor PSP.

  dbtrNm:application:

  dbtrAcctIban:

  rmtInf: Information supplied to enable the matching of an entry with the items that the transfer is intended to settle, such as commercial invoices in an accounts' receivable system.
  """
  def new(
        endToEndId,
        instdAmt,
        mndtId,
        dtOfSgntr,
        dbtrNm,
        dbtrAcctIban,
        dbtrAgtBic \\ "",
        rmtInf \\ ""
      ) do
    %__MODULE__{
      endToEndId: endToEndId,
      instdAmt: instdAmt,
      mndtId: mndtId,
      dtOfSgntr: dtOfSgntr,
      dbtrNm: dbtrNm,
      dbtrAcctIban: dbtrAcctIban,
      dbtrAgtBic: dbtrAgtBic,
      rmtInf: rmtInf
    }
  end

  @spec create([{any(), __MODULE__.t()}]) :: list()
  def create([]), do: []

  def create([{_, %__MODULE__{} = first} | rest]) do
    [do_create(first) | create(rest)]
  end

  defp do_create(%__MODULE__{} = drctDbtTxInf) do
    element(:DrctDbtTxInf, nil, [
      element(:PmtId, nil, [
        element(:EndToEndId, nil, drctDbtTxInf.endToEndId)
      ]),
      element(:InstdAmt, %{Ccy: "EUR"}, drctDbtTxInf.instdAmt),
      element(:DrctDbtTx, nil, [
        element(:MndtRltdInf, nil, [
          element(:MndtId, nil, drctDbtTxInf.mndtId),
          element(:DtOfSgntr, nil, drctDbtTxInf.dtOfSgntr)
        ])
      ]),
      element(:DbtrAgt, nil, [
        # <FinInstnId><BICFI>dbtrAgtBic</BICFI></FinInstnId> or by default <Othr><Id>NOTPROVIDED</Id></Othr>
        element(:FinInstnId, nil, [
          element(:BICFI, nil, drctDbtTxInf.dbtrAgtBic)
        ])
      ]),
      element(:Dbtr, nil, [
        element(:Nm, nil, drctDbtTxInf.dbtrNm)
      ]),
      element(:DbtrAcct, nil, [
        element(:Id, nil, [
          element(:IBAN, nil, drctDbtTxInf.dbtrAcctIban)
        ])
      ]),
      element(:RmtInf, nil, [
        element(:Ustrd, nil, drctDbtTxInf.rmtInf)
      ])
    ])
  end
end
