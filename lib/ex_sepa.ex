defmodule ExSepa do
  @moduledoc """
  Documentation for `ExSepa`.

  `ExSepa.DirectDebit` enables the creation of SEPA core direct debits.
  """

  @doc false
  def get_country_codes(),
    do: [
      "AD",
      "AT",
      "BE",
      "BG",
      "CH",
      "CY",
      "CZ",
      "DE",
      "DK",
      "EE",
      "ES",
      "FI",
      "FR",
      "GB",
      "GR",
      "HU",
      "HR",
      "IE",
      "IS",
      "LI",
      "LT",
      "LU",
      "LV",
      "MC",
      "NL",
      "MT",
      "NO",
      "IT",
      "PL",
      "PT",
      "RO",
      "SE",
      "SM",
      "SK",
      "SI"
      # ,    "VA" Vatican City State not in Faker iban list
    ]

  @doc false
  def test do
    # struct!(ExSepa.GroupHeader, [msgId: 1, initgPtyNm: "Irgendein Verein"])
    # %ExSepa.GroupHeader{msgId: 100, initgPtyNm: "Ein zweiter e.V."}
    # ExSepa.GroupHeader.new(%{msgId: 1, initgPtyNm: "Was"})
    # ExSepa.GroupHeader.new( 1, "Falsche Eingabe")

    dd = ExSepa.DirectDebit.new("Msg-ID-000100", "Ein Verein")

    xml =
      dd
      |> ExSepa.DirectDebit.add_payment_information(
        "Pmt-ID-001",
        Date.utc_today() |> Date.add(3),
        "DE00ZZZ00099999999",
        "Creditor Name",
        "DE87200500001234567890",
        "BANKDEFFXXX"
      )
      |> ExSepa.DirectDebit.add_transaction_information(
        "Pmt-ID-001",
          "EndToEndId-0001",
          100.01,
          "Mandate-Id-01",
          ~D[2021-01-21],
          "Debtor Name",
          "CH7280005000088877766",
          "RAIFCH22005",
          "Unstructured Remittance Information"
      )
      |> ExSepa.DirectDebit.to_xml()

    # xml = ExSepa.DirectDebit.to_xml(direct_debit)
    {:ok, file} = File.open("./pain.test.xml", [:write])
    IO.binwrite(file, xml)
    File.close(file)

    # {:ok, xsddoc} = File.read(Path.expand("./pain.008.001.08_GBIC_4.xsd"))

    # {:ok, model} = :erlsom.compile_xsd(xsddoc)
    # # {:ok, out, rest} = :erlsom.scan(xml, model)

    # :erlsom.scan(xml, model)
    # # case :erlsom.scan(xml, model) do
    # #   {:ok, _out, _rest} ->
    # #     # IO.puts(xml)
    # #     xml
    # #   {:error, reason} ->
    # #     # IO.puts("Error: #{reason}")
    # #     reason
    # # end
  end
end
