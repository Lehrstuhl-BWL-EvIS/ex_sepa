defmodule ExSepa.Validation do
  @moduledoc false

  defp in_language(string, pattern) do
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

    with :ok <-
           do_pattern_test(
             new_string,
             pattern
           ) do
      {:ok, new_string}
    end
  end

  defp do_pattern_test(string, pattern, acc \\ "")

  defp do_pattern_test("", _pattern, acc) do
    if acc == "",
      do: :ok,
      else: {:error, "These characters are not part of the pattern test: #{acc}"}
  end

  defp do_pattern_test(string, pattern, acc) do
    sl = String.length(string)
    run_string = Regex.run(pattern, string)

    if run_string == nil do
      do_pattern_test(String.slice(string, 1, sl - 1), pattern, acc <> String.at(string, 0))
    else
      new_string = Enum.join(run_string)
      nsl = String.length(new_string)

      if sl == nsl do
        do_pattern_test("", pattern, acc)
      else
        if new_string == String.slice(string, 0..(nsl - 1)) do
          do_pattern_test(
            String.slice(string, nsl + 1, sl - nsl - 1),
            pattern,
            acc <> String.at(string, nsl)
          )
        else
          do_pattern_test(new_string, pattern, acc <> String.at(string, 0))
        end
      end
    end
  end

  @spec text(keyword(binary())) :: :ok | {:error, String.t()}
  def text(text_tuple_list, pre_error_text \\ "") do
    case do_text(text_tuple_list, pre_error_text) do
      "" -> :ok
      e -> {:error, e}
    end
  end

  defp do_text([], acc), do: acc

  defp do_text([first | rest], acc) do
    {ato, tex} = first

    do_text(
      rest,
      acc <>
        case real_text(tex) do
          :ok ->
            ""

          {:error, e} ->
            " - #{ato}: " <> e
        end
    )
  end

  defp real_text(text) do
    with true <- is_binary(text),
         true <- String.valid?(text) do
      :ok
    else
      false ->
        {:error, "must be UTF-8 encoded binary"}
    end
  end

  defp character_set_start(text) do
    if text |> String.starts_with?("/"),
      do: {:error, "Text field must not begin with '/'"},
      else: :ok
  end

  defp character_set_end(text) do
    if text |> String.ends_with?("/"),
      do: {:error, "Text field must not end with '/'"},
      else: :ok
  end

  defp character_set_contain(text) do
    if text |> String.contains?("//"),
      do: {:error, "Text field must not contain '//'"},
      else: :ok
  end

  defp min_max_text(text, min_length, max_length) do
    case String.length(text) do
      x when x < min_length -> {:error, "Minimum length of #{min_length} characters"}
      x when x > max_length -> {:error, "Maximum length of #{max_length} characters"}
      _ -> :ok
    end
  end

  @doc """
  Checks the transferred text according to the EPC specifications and returns the text with the best practice conversion.
  """
  @spec max_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def max_text(element, text, length) do
    with :ok <- real_text(text),
         new_text = text |> String.trim(),
         :ok <- min_max_text(new_text, 1, length),
         {:ok, language_text} <-
           in_language(
             new_text,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]{1,#{length}}/
           ),
         :ok <- character_set_start(language_text),
         :ok <- character_set_end(language_text),
         :ok <- character_set_contain(language_text) do
      {:ok, language_text}
    else
      {:error, e} ->
        {:error, "#{element}: #{e}"}
    end
  end

  @spec optional_max_text(atom(), String.t(), non_neg_integer()) ::
          {:ok, String.t()} | {:error, String.t()}
  def optional_max_text(element, text, length) do
    if text |> String.trim() == "" do
      {:ok, ""}
    else
      max_text(element, text, length)
    end
  end

  @doc """
  Checks the amount entered. It must be between 0.01 and 999,999,999.99 euros.

  ## Examples

      iex> ExSepa.Validation.amount(50.0)
      :ok

      iex> ExSepa.Validation.amount(0.0)
      {:error, "The amount must be more then 0.00"}

      iex> ExSepa.Validation.amount(-53.15)
      {:error, "The amount must be more then 0.00"}

      iex> ExSepa.Validation.amount(4561237531.0)
      {:error, "The amount must be less then 999,999,999.99 euro"}

      iex> ExSepa.Validation.amount(30.303)
      {:error, "Amount has too many decimal places"}
  """
  @spec amount(float()) :: :ok | {:error, String.t()}
  def amount(amount) do
    if amount <= 0.0 do
      {:error, "The amount must be more then 0.00"}
    else
      integer = round(amount * 100)

      if length(Integer.digits(integer)) > 11 do
        {:error, "The amount must be less then 999,999,999.99 euro"}
      else
        if integer / 100.0 == amount do
          :ok
        else
          {:error, "Amount has too many decimal places"}
        end
      end
    end
  end

  @spec due_date(Date.t()) :: :ok | {:error, String.t()}
  def due_date(%Date{} = date) do
    case Date.compare(Date.utc_today(), date) do
      :lt -> :ok
      _ -> {:error, "The due date must be in the future."}
    end
  end

  @spec date(Date.t()) :: :ok | {:error, String.t()}
  def date(%Date{} = date) do
    case Date.compare(date, Date.utc_today()) do
      :lt -> :ok
      _ -> {:error, "Date must be in the past."}
    end
  end

  @spec iban(String.t()) :: :ok | {:error, String.t()}
  def iban(iban) do
    case Bankster.iban_validate(iban) do
      {:ok, _iban} -> :ok
      {:error, e} -> {:error, e}
    end
  end

  @spec bic(String.t()) :: :ok | {:error, String.t()}
  def bic(bic) do
    if bic == "" do
      :ok
    else
      case Bankster.bic_valid?(bic) do
        true -> :ok
        false -> {:error, "BIC is not valid"}
      end
    end
  end

  @spec country_code(String.t()) :: :ok | {:error, String.t()}
  def country_code(country) do
    with :ok <- do_pattern_test(country, ~r/[A-Z]{2,2}/) do
      if Enum.member?(ExSepa.get_bic_country_codes(), country) do
        :ok
      else
        {:error, "Country code not in list!"}
      end
    end
  end

  @doc """
  Checks whether the transmitted country code corresponds to one of the EEA countries and, if applicable, whether an address has been specified.

  ## Examples

      iex> ExSepa.Validation.address_mandatory("DE", "", nil)
      :ok

      iex> ExSepa.Validation.address_mandatory("AD", "", nil)
      {:error, "BIC is mandatory for non-EEA SEPA country or territory"}

      iex> ExSepa.Validation.address_mandatory("AD", "CASBADADXXX", nil)
      {:error, "Address is mandatory for non-EEA SEPA country or territory"}

      iex> ExSepa.Validation.address_mandatory("AD", "CASBADADXXX", %ExSepa.Address{town_name: "Andorra la Vella", country: "AD"})
      :ok
  """
  @spec address_mandatory(String.t(), String.t(), ExSepa.Address.t() | nil) ::
          :ok | {:error, String.t()}
  def address_mandatory(country, bic, address) do
    with :ok <- do_pattern_test(country, ~r/[A-Z]{2,2}/) do
      if Enum.member?(ExSepa.get_eea_iban_country_codes(), country) do
        :ok
      else
        cond do
          bic == "" ->
            {:error, "BIC is mandatory for non-EEA SEPA country or territory"}

          address == nil ->
            {:error, "Address is mandatory for non-EEA SEPA country or territory"}

          true ->
            :ok
        end
      end
    end
  end
end
