defmodule ExSepa.Validation do
  @moduledoc false

  @doc """
  Latin character set used for SEPA messages
  """
  @spec in_language(String.t()) :: {:ok, String.t()} | {:error, String.t()}
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

    with :ok <-
           do_pattern_test(
             new_string,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]+/
           ) do
      {:ok, new_string}
    end
  end

  def do_pattern_test(string, pattern, acc \\ "")

  def do_pattern_test("", _pattern, acc) do
    if acc == "",
      do: :ok,
      else: {:error, "These characters are not part of the pattern test: #{acc}"}
  end

  def do_pattern_test(string, pattern, acc) do
    sl = String.length(string)
    run_string = Regex.run(pattern, string)

    if run_string == nil do
      do_pattern_test(String.slice(string, 1, sl - 1), pattern, acc <> String.at(string, 0))
    else
      new_string = Enum.join(run_string)
      nsl = String.length(new_string)
      # IO.puts("string: #{string}; sl: #{sl}; new: #{new_string}; nsl: #{nsl}")

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

  @spec real_text(String.t()) :: :ok | {:error, String.t()}
  def real_text(text) do
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

  @spec min_max_text(String.t(), integer(), integer()) :: :ok | {:error, String.t()}
  defp min_max_text(text, min_length, max_length) do
    case String.length(text) do
      x when x < min_length -> {:error, "Minimum length of #{min_length} characters"}
      x when x > max_length -> {:error, "Maximum length of #{max_length} characters"}
      _ -> :ok
    end
  end

  def in_latin_character_set(text) do
    case in_language(text) do
      {:ok, language_text} -> {:ok, language_text}
      {:error, e} -> {:error, "#{e}"}
    end
  end

  @spec max_35_text(atom(), String.t()) :: :ok | {:error, String.t()}
  def max_35_text(element, text) do
    with :ok <- real_text(text),
         new_text = text |> String.trim(),
         :ok <- min_max_text(new_text, 1, 35),
         :ok <-
           do_pattern_test(
             new_text,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]{1,35}/
           ),
         :ok <- character_set_start(new_text),
         :ok <- character_set_end(new_text),
         :ok <- character_set_contain(new_text) do
      :ok
    else
      {:error, e} ->
        {:error, "#{element}: #{e}"}
    end
  end

  @spec max_70_text(atom(), String.t()) :: :ok | {:error, String.t()}
  def max_70_text(element, text) do
    with :ok <- real_text(text),
         new_text = text |> String.trim(),
         :ok <- min_max_text(new_text, 1, 70),
         :ok <-
           do_pattern_test(
             new_text,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]{1,70}/
           ),
         :ok <- character_set_start(new_text),
         :ok <- character_set_end(new_text),
         :ok <- character_set_contain(new_text) do
      :ok
    else
      {:error, e} ->
        {:error, "#{element}: #{e}"}
    end
  end

  @spec max_140_text(atom(), String.t()) :: :ok | {:error, String.t()}
  def max_140_text(element, text) do
    with :ok <- real_text(text),
         new_text = text |> String.trim(),
         :ok <- min_max_text(new_text, 1, 140),
         :ok <-
           do_pattern_test(
             new_text,
             ~r/[a-zA-Z0-9|\x2F|\x2D|\x3F|\x3A|\x28|\x29|\x2E|\x20|\x2C|\x27|\x2B]{1,140}/
           ),
         :ok <- character_set_start(new_text),
         :ok <- character_set_end(new_text),
         :ok <- character_set_contain(new_text) do
      :ok
    else
      {:error, e} ->
        {:error, "#{element}: #{e}"}

      _ ->
        :unexpected_error
    end
  end

  @spec optional_max_140_text(atom(), String.t()) :: :ok | {:error, String.t()}
  def optional_max_140_text(element, text) do
    if text |> String.trim() == "" do
      :ok
    else
      max_140_text(element, text)
    end
  end

  @spec amount(float()) :: :ok | {:error, String.t()}
  def amount(amount) do
    if amount <= 0.0 do
      {:error, "The amount must be more then 0.00"}
    else
      integer = round(amount * 100)

      if length(Integer.digits(integer)) > 18 do
        {:error, "The amount is too high"}
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
end
