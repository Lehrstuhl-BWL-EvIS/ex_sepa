defmodule ExSepa do
  @moduledoc """
  Documentation for `ExSepa`.

  `ExSepa.DirectDebit` enables the creation of SEPA core direct debits.
  """

  # @doc """
  # Latin character set used for SEPA messages
  # """
  @doc false
  def in_language(string) do
    new_string =
      string
      |> String.replace("ä", "a")
      |> String.replace("ö", "o")
      |> String.replace("ü", "u")
      |> String.replace("Ä", "a")
      |> String.replace("Ö", "o")
      |> String.replace("Ü", "u")
      |> String.replace("ß", "s")
      |> String.replace("&", "+")
      |> String.replace("*", ".")
      |> String.replace("$", ".")
      |> String.replace("%", ".")

    case do_in_language(new_string) do
      "" ->
        :ok

      e ->
        {:error, "These characters are not part of the Latin character set: #{e}"}
    end
  end

  defp do_in_language(string, acc \\ "")
  defp do_in_language("", acc), do: acc

  defp do_in_language(string, acc) do
    sl = String.length(string)
    run_string = Regex.run(~r/[a-zA-Z-\s(\/?:.,'+)\d]+/, string)

    if run_string == nil do
      do_in_language(String.slice(string, 1, sl - 1), acc <> String.at(string, 0))
    else
      new_string = Enum.join(run_string)
      nsl = String.length(new_string)
      # IO.puts("string: #{string}; sl: #{sl}; new: #{new_string}; nsl: #{nsl}")

      if sl == nsl do
        do_in_language("", acc)
      else
        do_in_language(String.slice(string, nsl + 1, sl - nsl - 1), acc <> String.at(string, nsl))
      end
    end
  end

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
