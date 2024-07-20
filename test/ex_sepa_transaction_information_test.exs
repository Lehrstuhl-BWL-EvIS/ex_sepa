defmodule ExSepaTransactionInformationTest do
  use ExUnit.Case, async: false
  import ExSepa, only: [get_iban_country_codes: 0]
  doctest ExSepa.TransactionInformation

  describe "ExSepa.TransactionInformation new" do
    test "ok" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:ok,
                %ExSepa.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  mandate_id: mndt_id,
                  mandate_signing_date: mndt_date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  debtor_bic: "",
                  remittance_information: ""
                }}
    end

    test "with BIC - ok" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      [debtor_bic | _] =
        Regex.run(
          ~r/[A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}/,
          Faker.Util.format("%#{Faker.random_between(8, 11)}A")
        )

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic
             }) ==
               {:ok,
                %ExSepa.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  mandate_id: mndt_id,
                  mandate_signing_date: mndt_date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  debtor_bic: debtor_bic,
                  remittance_information: ""
                }}
    end

    test "with BIC and remittance_information - ok" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      [debtor_bic | _] =
        Regex.run(
          ~r/[A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}/,
          Faker.Util.format("%#{Faker.random_between(8, 11)}A")
        )

      remittance_information = Faker.Beer.yeast()

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic,
               "remittance_information" => remittance_information
             }) ==
               {:ok,
                %ExSepa.TransactionInformation{
                  end_to_end_id: endtoendid,
                  amount: amount,
                  mandate_id: mndt_id,
                  mandate_signing_date: mndt_date,
                  debtor_name: debtor_name,
                  debtor_iban: debtor_iban,
                  debtor_bic: debtor_bic,
                  remittance_information: remittance_information
                }}
    end

    test "with BIC and remittance_information - fail on remittance_information" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      [debtor_bic | _] =
        Regex.run(
          ~r/[A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}/,
          Faker.Util.format("%#{Faker.random_between(8, 11)}A")
        )

      remittance_information = "&" <> Faker.Beer.yeast()

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic,
               "remittance_information" => remittance_information
             }) ==
               {:error,
                "remittance_information: These characters are not part of the pattern test: &"}
    end

    test "endtoendid - fail UTF-8" do
      endtoendid = 951_753
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error,
                "Parameters must be strings. - end_to_end_id: must be UTF-8 encoded binary"}
    end

    test "endtoendid - fail latin character set" do
      endtoendid = Faker.Person.Hy.name()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert match?(
               {:error, _},
               ExSepa.TransactionInformation.new(%{
                 "end_to_end_id" => endtoendid,
                 "amount" => amount,
                 "mandate_id" => mndt_id,
                 "mandate_signing_date" => mndt_date,
                 "debtor_name" => debtor_name,
                 "debtor_iban" => debtor_iban
               })
             )
    end

    test "endtoendid - fail length" do
      endtoendid = Faker.Util.join(5, "-", &Faker.Gov.Us.ssn/0)
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "end_to_end_id: Maximum length of 35 characters"}
    end

    test "amount - fail UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Date.utc_today()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "amount must be a float(18.2)"}
    end

    test "amount - fail 0" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = 0
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "amount must be a float(18.2)"}
    end

    test "amount - fail 0.0" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = 0.0
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "The amount must be more then 0.00"}
    end

    test "amount - fail negativ" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = -50.20
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "The amount must be more then 0.00"}
    end

    test "amount - fail too many decimal places" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = 50.2053
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "Amount has too many decimal places"}
    end

    test "mndt_id - fail UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = 123_789
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "Parameters must be strings. - mandate_id: must be UTF-8 encoded binary"}
    end

    test "mndt_id - fail other" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Util.join(5, "-", &Faker.Gov.Us.ein/0)
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "mandate_id: Maximum length of 35 characters"}
    end

    test "mndt_date - fail UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = "the fourth of april"
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "mandate_signing_date must be a date"}
    end

    test "mndt_date - fail other" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.forward(Faker.Random.Elixir.random_between(1, 30))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) == {:error, "Date must be in the past."}
    end

    test "fail: debtor_name UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = 123_456_789
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "Parameters must be strings. - debtor_name: must be UTF-8 encoded binary"}
    end

    test "fail: debtor_name length" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))

      debtor_name =
        Faker.Util.join(20, " ", &Faker.Person.first_name/0) <> " " <> Faker.Person.name()

      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "debtor_name: Maximum length of 70 characters"}
    end

    test "fail: debtor_name start with /" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = "/" <> Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "debtor_name: Text field must not begin with '/'"}
    end

    test "fail: debtor_name ends with /" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name() <> "/"
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "debtor_name: Text field must not end with '/'"}
    end

    test "fail: debtor_name contains //" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.first_name() <> " // " <> Faker.Person.last_name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "debtor_name: Text field must not contain '//'"}
    end

    test "fail: debtor_iban invalid" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()

      [debtor_iban | _] =
        Regex.run(
          ~r/[A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}/,
          Faker.Util.format("%#{Faker.random_between(13, 15)}A")
        )

      # could be {:error, :invalid_country} or {:error, :invalid_length}
      assert match?(
               {:error, _},
               ExSepa.TransactionInformation.new(%{
                 "end_to_end_id" => endtoendid,
                 "amount" => amount,
                 "mandate_id" => mndt_id,
                 "mandate_signing_date" => mndt_date,
                 "debtor_name" => debtor_name,
                 "debtor_iban" => debtor_iban
               })
             )
    end

    test "fail: debtor_iban UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = 123_456_789

      # could be {:error, :invalid_country} or {:error, :invalid_length}
      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban
             }) ==
               {:error, "Parameters must be strings. - debtor_iban: must be UTF-8 encoded binary"}
    end

    test "debtor_bic - fail - UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())
      debtor_bic = 123_456_789

      remittance_information =
        Faker.Beer.yeast() <> Faker.Util.join(11, ", ", &Faker.Code.isbn13/0)

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic,
               "remittance_information" => remittance_information
             }) ==
               {:error, "Parameters must be strings. - debtor_bic: must be UTF-8 encoded binary"}
    end

    test "debtor_bic - fail - length" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())
      debtor_bic = Faker.Util.format("%#{Faker.random_between(12, 20)}A")

      remittance_information =
        Faker.Beer.yeast() <> Faker.Util.join(11, ", ", &Faker.Code.isbn13/0)

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic,
               "remittance_information" => remittance_information
             }) ==
               {:error, "BIC is not valid"}
    end

    test "remittance_information - fail - length" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      [debtor_bic | _] =
        Regex.run(
          ~r/[A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}/,
          Faker.Util.format("%#{Faker.random_between(8, 11)}A")
        )

      remittance_information =
        Faker.Beer.yeast() <> Faker.Util.join(11, ", ", &Faker.Code.isbn13/0)

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic,
               "remittance_information" => remittance_information
             }) ==
               {:error, "remittance_information: Maximum length of 140 characters"}
    end

    test "remittance_information - fail - UTF-8" do
      endtoendid = Faker.Gov.Us.ssn()
      amount = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      [debtor_bic | _] =
        Regex.run(
          ~r/[A-Z0-9]{4,4}[A-Z]{2,2}[A-Z0-9]{2,2}([A-Z0-9]{3,3}){0,1}/,
          Faker.Util.format("%#{Faker.random_between(8, 11)}A")
        )

      remittance_information = 123_456_789

      assert ExSepa.TransactionInformation.new(%{
               "end_to_end_id" => endtoendid,
               "amount" => amount,
               "mandate_id" => mndt_id,
               "mandate_signing_date" => mndt_date,
               "debtor_name" => debtor_name,
               "debtor_iban" => debtor_iban,
               "debtor_bic" => debtor_bic,
               "remittance_information" => remittance_information
             }) ==
               {:error,
                "Parameters must be strings. - remittance_information: must be UTF-8 encoded binary"}
    end
  end
end
