defmodule ExSepa do
  @moduledoc """
  Documentation for `ExSepa`.

  `ExSepa.DirectDebit` enables the creation of SEPA core direct debits.
  """

  @doc false
  def get_eea_iban_country_codes(),
    do: [
      "AT",
      "BE",
      "BG",
      "CY",
      "CZ",
      "DE",
      "DK",
      "EE",
      "ES",
      "FI",
      "FR",
      "GR",
      "HU",
      "HR",
      "IE",
      "IS",
      "LI",
      "LT",
      "LU",
      "LV",
      "NL",
      "MT",
      "NO",
      "IT",
      "PL",
      "PT",
      "RO",
      "SE",
      "SK",
      "SI"
    ]

  @doc false
  def get_non_eea_iban_country_codes(),
    do: [
      "AD",
      "CH",
      "GB",
      "MC",
      "SM"
      # ,    "VA" Vatican City State not in Faker iban list
    ]

  @doc """
  List with IBAN country codes used in IBANs according to ISO 3166
  """
  def get_iban_country_codes(),
    do: Enum.concat(get_eea_iban_country_codes(), get_non_eea_iban_country_codes())

  @doc false
  def get_eea_bic_country_codes(),
    do: [
      "AT",
      "BE",
      "BG",
      "BL",
      "CY",
      "CZ",
      "DE",
      "DK",
      "EE",
      "ES",
      "FI",
      "FR",
      "GF",
      "GP",
      "GR",
      "HU",
      "HR",
      "IE",
      "IS",
      "LI",
      "LT",
      "LU",
      "LV",
      "NL",
      "MF",
      "MT",
      "MQ",
      "NO",
      "IT",
      "PL",
      "PT",
      "RE",
      "RO",
      "SE",
      "SK",
      "SI",
      "YT"
    ]

  @doc false
  def get_non_eea_bic_country_codes(),
    do: [
      "AD",
      "CH",
      "GB",
      "GG",
      "IM",
      "JE",
      "MC",
      "PM",
      "SM"
      # ,    "VA" Vatican City State not in Faker iban list
    ]

  @doc """
  List with BIC country codes used in BICs according to ISO 3166
  """
  def get_bic_country_codes(),
    do: Enum.concat(get_eea_bic_country_codes(), get_non_eea_bic_country_codes())

  @doc false
  def test do
    # struct!(ExSepa.GroupHeader, [msgId: 1, initgPtyNm: "Some club"])
    # %ExSepa.GroupHeader{msg_id: 100, initiating_party_name: "A second one"}
    # ExSepa.GroupHeader.new(%{msgId: 1, initgPtyNm: "Name"})
    # ExSepa.GroupHeader.new( 1, "Incorrect input")

    direct_debit =
      ExSepa.DirectDebit.new(%{
        "msg_id" => "Msg-ID-000100",
        "initiating_party_name" => "Club name"
      })

    direct_debit =
      ExSepa.CustomerDirectDebitInitiationV08.add_payment_information(
        direct_debit,
        %{
          "payment_id" => "Payment-ID-0001",
          "due_date" => %Date{} = ~D[2024-07-24],
          "creditor_id" => "DE00ZZZ00099999999",
          "creditor_name" => "Creditor Name",
          "creditor_iban" => "DE87200500001234567890",
          "creditor_bic" => "BANKDEFFXXX"
        }
      )

    direct_debit =
      ExSepa.CustomerDirectDebitInitiationV08.add_payment_information(
        direct_debit,
        %{
          "payment_id" => "Payment-ID-0002",
          "due_date" => %Date{} = ~D[2024-07-29],
          "creditor_id" => "DE00ZZZ00099999999",
          "creditor_name" => "Creditor Name",
          "creditor_iban" => "DE87200500001234567890"
        }
      )

    direct_debit =
      ExSepa.CustomerDirectDebitInitiationV08.add_transaction_information(
        direct_debit,
        "Payment-ID-0001",
        %{
          "end_to_end_id" => "EndToEndId-0001",
          "amount" => 100.01,
          "mandate_id" => "Mandate-Id-01",
          "mandate_signing_date" => ~D[2021-01-21],
          "debtor_name" => "Debtor Name",
          "debtor_iban" => "CH7280005000088877766",
          "debtor_bic" => "BANKDEFFXXX",
          "remittance_information" => "Remittance Information 1"
        }
      )

    direct_debit =
      ExSepa.CustomerDirectDebitInitiationV08.add_transaction_information(
        direct_debit,
        "Payment-ID-0002",
        %{
          "end_to_end_id" => "EndToEndId-0001",
          "amount" => 100.02,
          "mandate_id" => "Mandate-Id-02",
          "mandate_signing_date" => ~D[2022-02-22],
          "debtor_name" => "Debtor Two",
          "debtor_iban" => "CH7280005000088877766",
          "remittance_information" => "Remittance Information 2"
        }
      )

    xml = ExSepa.DirectDebit.to_xml(direct_debit)


    {:ok, xsddoc} = File.read(Path.expand("./lib/ex_sepa/pain.008.001.08_GBIC_4.xsd"))

    {:ok, model} = :erlsom.compile_xsd(xsddoc)

    :erlsom.scan(xml, model)

    case :erlsom.scan(xml, model) do
      {:ok, _out, _rest} ->
        {:ok, xml}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
