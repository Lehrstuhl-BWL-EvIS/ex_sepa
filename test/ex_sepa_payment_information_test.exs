defmodule ExSepaPaymentInformationTest do
  use ExUnit.Case, async: true
  import ExSepa, only: [get_eea_iban_country_codes: 0]
  doctest ExSepa.PaymentInformation

  describe "ExSepa.PaymentInformation new" do
    test "ok" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:ok,
                %ExSepa.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "CIDZZZ00000001",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban
                }}
    end

    test "with BIC - ok" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "BANKDEFFXXX"
             }) ==
               {:ok,
                %ExSepa.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "CIDZZZ00000001",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: "BANKDEFFXXX"
                }}
    end

    test "with BIC and sequence_type - ok" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "BANKDEFFXXX",
               sequence_type: :First
             }) ==
               {:ok,
                %ExSepa.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "CIDZZZ00000001",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_bic: "BANKDEFFXXX",
                  sequence_type: :First
                }}
    end

    test "with address - ok" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      city = Faker.Address.city()
      country_codes = Enum.drop(get_eea_iban_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_address: %{town_name: city, country: country}
             }) ==
               {:ok,
                %ExSepa.PaymentInformation{
                  payment_id: payment_id,
                  due_date: date,
                  creditor_id: "CIDZZZ00000001",
                  creditor_name: creditor_name,
                  creditor_iban: creditor_iban,
                  creditor_address: %ExSepa.Address{town_name: city, country: country}
                }}
    end

    test "fail: wrong payment_id 1" do
      payment_id = Faker.Util.format("%3A-ID-%#{Faker.random_between(35, 50)}d")
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "payment_id: Maximum length of 35 characters"}
    end

    test "fail: wrong payment_id 2" do
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: 00_000_001,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "Parameters must be strings. - payment_id: must be UTF-8 encoded binary"}
    end

    test "fail: wrong date 1" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today()
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "The due date must be in the future."}
    end

    test "fail: wrong date 2" do
      payment_id = Faker.Gov.Us.ein()
      date = "text"
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "Parameter due_date must be a date"}
    end

    test "fail: wrong creditor_id 1" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_id = Faker.Util.format("%3AZZZ%#{Faker.random_between(35, 50)}d")
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: creditor_id,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "creditor_id: Maximum length of 35 characters"}
    end

    test "fail: wrong creditor_id 2" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: 00_000_001,
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error, "Parameters must be strings. - creditor_id: must be UTF-8 encoded binary"}
    end

    test "fail: wrong Name 1" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)

      creditor_name =
        Faker.Util.format(
          "%1A%#{Faker.random_between(34, 40)}a %1A%#{Faker.random_between(34, 40)}a"
        )

      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) == {:error, "creditor_name: Maximum length of 70 characters"}
    end

    test "fail: wrong Name 2" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Date.utc_today() |> Date.add(3)
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             }) ==
               {:error,
                "Parameters must be strings. - creditor_name: must be UTF-8 encoded binary"}
    end

    test "fail: wrong IBAN 1" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Util.format("%2A%2d%#{Faker.random_between(2, 40)}d")

      # could be {:error, :invalid_country} or {:error, :invalid_length}
      assert match?(
               {:error, _},
               ExSepa.PaymentInformation.new(%{
                 payment_id: payment_id,
                 due_date: date,
                 creditor_id: "CIDZZZ00000001",
                 creditor_name: creditor_name,
                 creditor_iban: creditor_iban
               })
             )
    end

    test "fail: wrong IBAN 2" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: 123_456_789
             }) ==
               {:error,
                "Parameters must be strings. - creditor_iban: must be UTF-8 encoded binary"}
    end

    test "with BIC - fail: wrong BIC 1" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "Foo"
             }) ==
               {:error, "BIC is not valid"}
    end

    test "with BIC - fail: wrong BIC 2" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: 123
             }) ==
               {:error,
                "Parameters must be strings. - creditor_bic: must be UTF-8 encoded binary"}
    end

    test "with BIC and sequence_type - fail: wrong sequence_type 1" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               sequence_type: :Foo
             }) ==
               {:error,
                "Parameter sequence_type must be an atom :OneOff, :First, :Recurring, :Final"}
    end

    test "with BIC and sequence_type - fail: wrong sequence_type 2" do
      payment_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      assert ExSepa.PaymentInformation.new(%{
               payment_id: payment_id,
               due_date: date,
               creditor_id: "CIDZZZ00000001",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               sequence_type: "Foo"
             }) ==
               {:error,
                "Parameter sequence_type must be an atom :OneOff, :First, :Recurring, :Final"}
    end

    test "error: missing key :creditor_iban" do
      assert ExSepa.PaymentInformation.new(%{
               payment_id: Faker.Gov.Us.ein(),
               due_date: Date.utc_today() |> Date.add(3),
               creditor_id: "DE98ZZZ09999999999",
               creditor_name: Faker.Team.name()
             }) ==
               {:error, "missing keys: [:creditor_iban]"}
    end
  end
end
