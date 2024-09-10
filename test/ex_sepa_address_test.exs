defmodule ExSepaAddressTest do
  use ExUnit.Case, async: true
  import ExSepa, only: [get_bic_country_codes: 0]
  doctest ExSepa.Address

  describe "ExSepa.Address new " do
    test "Random city and country" do
      city = Faker.Address.city()
      country_codes = Enum.drop(get_bic_country_codes(), -1)

      country =
        Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

      assert ExSepa.Address.new(%{town_name: city, country: country}) ==
               {:ok,
                %ExSepa.Address{
                  department: nil,
                  sub_department: nil,
                  street_name: nil,
                  building_number: nil,
                  building_name: nil,
                  floor: nil,
                  post_box: nil,
                  room: nil,
                  post_code: nil,
                  town_name: city,
                  town_location_name: nil,
                  district_name: nil,
                  country_sub_division: nil,
                  country: country
                }}
    end
  end

  test "Random second address" do
    city = Faker.Address.city()
    country_sub_division = Faker.Address.state()
    room = Faker.Address.secondary_address()
    street_name = Faker.Address.street_name()
    building_number = Faker.Address.building_number()
    post_code = Faker.Address.zip_code()
    country_codes = Enum.drop(get_bic_country_codes(), -1)

    country =
      Enum.at(country_codes, Faker.Random.Elixir.random_between(0, length(country_codes) - 1))

    assert ExSepa.Address.new(%{
             town_name: city,
             country: country,
             post_code: post_code,
             building_number: building_number,
             street_name: street_name,
             room: room,
             country_sub_division: country_sub_division
           }) ==
             {:ok,
              %ExSepa.Address{
                department: nil,
                sub_department: nil,
                street_name: street_name,
                building_number: building_number,
                building_name: nil,
                floor: nil,
                post_box: nil,
                room: room,
                post_code: post_code,
                town_name: city,
                town_location_name: nil,
                district_name: nil,
                country_sub_division: country_sub_division,
                country: country
              }}
  end
end
