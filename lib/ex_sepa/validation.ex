defmodule ExSepa.Validation do
  @moduledoc false

  @doc """
  Latin character set used for SEPA messages
  """
  @spec in_language(String.t()) :: :ok | {:error, String.t()}
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
        {:error, "These characters are not part of the authorised Latin character set: #{e}"}
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

  @spec text([{atom(), any()}], String.t()) :: :ok | {:error, String.t()}
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
        case real_text(ato, tex) do
          :ok ->
            ""

          {:error, e} ->
            " - " <> e
        end
    )
  end

  @spec real_text(atom(), String.t()) :: :ok | {:error, String.t()}
  def real_text(element, text) do
    case is_binary(text) do
      true ->
        case String.valid?(text) do
          true ->
            case in_language(text) do
              :ok -> :ok
              {:error, e} -> {:error, "#{element} - #{e}"}
            end

          _ ->
            {:error, "#{element}: must be UTF-8 encoded binary"}
        end

      _ ->
        {:error, "#{element}: must be UTF-8 encoded binary"}
    end
  end

  @spec max_text(atom(), String.t(), integer()) :: :ok | {:error, String.t()}
  def max_text(element, text, max_length) do
    case real_text(element, text) do
      :ok ->
        case String.length(text) do
          x when x <= max_length -> :ok
          _ -> {:error, "#{element}: maximum length of #{max_length} characters"}
        end

      {:error, e} ->
        {:error, e}
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
