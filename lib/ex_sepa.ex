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
    ExSepa.GroupHeader.new("Msg-ID-000100", "Ein Fußballclub")
    # ExSepa.GroupHeader.new(%{msgId: 1, initgPtyNm: "Was"})
    # ExSepa.GroupHeader.new( 1, "Falsche Eingabe")
  end
end
