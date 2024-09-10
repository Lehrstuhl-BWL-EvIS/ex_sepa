defmodule ExSepaTest do
  use ExUnit.Case, async: true
  import ExSepa, only: [get_eea_iban_country_codes: 0]
  doctest ExSepa.DirectDebit

  describe "ExSepa.DirectDebit new Initiation Message" do
    test "Generate a new direct debit" do
      assert ExSepa.DirectDebit.new(%{
               msg_id: "Msg-ID-001",
               initiating_party_name: "Initiating Party"
             }) ==
               %ExSepa.DirectDebit{
                 group_header: %ExSepa.GroupHeader{
                   msg_id: "Msg-ID-001",
                   initiating_party_name: "Initiating Party"
                 },
                 payment_information: nil
               }
    end

    test "Generate a new direct debit - fail: msg_id is not a String" do
      assert_raise ExSepa.GroupHeaderError, "msg_id: must be UTF-8 encoded binary", fn ->
        ExSepa.DirectDebit.new(%{
          msg_id: <<0xFFFF::16>>,
          initiating_party_name: "Initiating Party"
        })
      end
    end

    test "Generate a new direct debit - fail: initiating_party_name is not a String" do
      assert_raise ExSepa.GroupHeaderError,
                   "initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: "001",
                       initiating_party_name: <<0xFFFF::16>>
                     })
                   end
    end

    test "Generate a new direct debit - fail on msg_id" do
      assert_raise ExSepa.GroupHeaderError,
                   "Parameters must be strings. - msg_id: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: 000_001,
                       initiating_party_name: "Initiating Party"
                     })
                   end
    end

    test "Generate a new direct debit - fail on initiating_party_name" do
      assert_raise ExSepa.GroupHeaderError,
                   "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: "Msg-ID-000100",
                       initiating_party_name: 345
                     })
                   end
    end

    test "Generate a new direct debit - fail on msg_id and initiating_party_name" do
      assert_raise ExSepa.GroupHeaderError,
                   "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: 00450,
                       initiating_party_name: 123_456
                     })
                   end
    end

    test "Generate a new direct debit - fail: on msg_id length" do
      assert_raise ExSepa.GroupHeaderError, "msg_id: Maximum length of 35 characters", fn ->
        ExSepa.DirectDebit.new(%{
          msg_id: "0123456789012345678901234567890123456789",
          initiating_party_name: "Initiating Party"
        })
      end
    end

    test "Generate a new direct debit - fail: on initiating_party_name length" do
      assert_raise ExSepa.GroupHeaderError,
                   "initiating_party_name: Maximum length of 70 characters",
                   fn ->
                     ExSepa.DirectDebit.new(%{
                       msg_id: "ID-0001",
                       initiating_party_name:
                         "The name of the person who has initiated the call is too long to be entered in this field."
                     })
                   end
    end
  end

  describe "ExSepa.DirectDebit new Payment Information" do
    test "Generate a new Payment Information - :ok" do
      date = Date.utc_today() |> Date.add(5)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      assert ExSepa.DirectDebit.add_payment_information(
               direct_debit,
               %{
                 payment_id: "Pmt-ID-001",
                 due_date: date,
                 creditor_id: "DE00ZZZ00099999999",
                 creditor_name: "Creditor Name",
                 creditor_iban: "DE87200500001234567890",
                 creditor_bic: "BANKDEFFXXX"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "DE00ZZZ00099999999",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "BANKDEFFXXX"
                 }
               ]
             }
    end

    test "Generate a second new Payment Information - :ok" do
      date = Date.utc_today() |> Date.add(5)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      assert direct_debit
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: "Pmt-ID-001",
               due_date: date,
               creditor_id: "DE00ZZZ00099999999",
               creditor_name: "Creditor Name",
               creditor_iban: "DE87200500001234567890"
             })
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: "Pmt-ID-002",
               due_date: date |> Date.add(2),
               creditor_id: "DE00ZZZ00099999999",
               creditor_name: "Creditor Name",
               creditor_iban: "DE87200500001234567890"
             }) == %ExSepa.DirectDebit{
               group_header: %ExSepa.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-002",
                   due_date: date |> Date.add(2),
                   creditor_id: "DE00ZZZ00099999999",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890"
                 },
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "DE00ZZZ00099999999",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890"
                 }
               ]
             }
    end

    test "Generate a second new Payment Information - fail: same payment_id" do
      date = Date.utc_today() |> Date.add(5)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      assert_raise ExSepa.PaymentInformationError, "payment_id: Pmt-ID-001 already exists", fn ->
        direct_debit
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Pmt-ID-001",
          due_date: date,
          creditor_id: "DE00ZZZ00099999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Pmt-ID-001",
          due_date: date,
          creditor_id: "DE00ZZZ00099999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
      end
    end
  end

  describe "ExSepa.DirectDebit new Transaction Information" do
    test "Generate a new Transaction Information 1" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "CIDZZZ00000001",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890",
            creditor_bic: "BANKDEFFXXX"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               %{
                 end_to_end_id: "EndToEndId-0001",
                 amount: 100.01,
                 mandate_id: "Mandate-Id-01",
                 mandate_signing_date: ~D[2021-01-21],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "CIDZZZ00000001",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "BANKDEFFXXX",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "error: BIC is mandatory" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "DE00ZZZ00099999999",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      assert_raise ExSepa.TransactionInformationError,
                   "BIC is mandatory for non-EEA SEPA country or territory",
                   fn ->
                     ExSepa.DirectDebit.add_transaction_information(
                       direct_debit,
                       "Pmt-ID-001",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         mandate_id: "Mandate-Id-01",
                         mandate_signing_date: ~D[2021-01-21],
                         debtor_name: "Debtor Name",
                         debtor_address: %{town_name: "Bern", country: "CH"},
                         debtor_iban: "CH7280005000088877766",
                         remittance_information: "Unstructured Remittance Information"
                       }
                     )
                   end
    end

    test "Generate a new Transaction Information 3" do
      date = Date.utc_today() |> Date.add(3)

      dd =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: "Pmt-ID-001",
               due_date: date,
               creditor_id: "DE00ZZZ00099999999",
               creditor_name: "Creditor Name",
               creditor_iban: "DE87200500001234567890",
               creditor_bic: "BANKDEFFXXX"
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               "Pmt-ID-001",
               %{
                 end_to_end_id: "EndToEndId-0001",
                 amount: 100.01,
                 mandate_id: "Mandate-Id-01",
                 mandate_signing_date: ~D[2021-01-21],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "DE00ZZZ00099999999",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "BANKDEFFXXX",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate a new Transaction Information 4" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "CIDZZZ00000001",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               %{
                 end_to_end_id: "EndToEndId-0001",
                 amount: 100.01,
                 mandate_id: "Mandate-Id-01",
                 mandate_signing_date: ~D[2021-01-21],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.GroupHeader{
                 msg_id: "Msg-ID-001",
                 initiating_party_name: "Initiating Party"
               },
               payment_information: [
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "CIDZZZ00000001",
                   creditor_name: "Creditor Name",
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate two Payment Information with two Transaction Informations" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "CIDZZZ00000001",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-002",
            due_date: date |> Date.add(1),
            creditor_id: "CIDZZZ00000001",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Pmt-ID-001",
          %{
            end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            mandate_id: "Mandate-Id-01",
            mandate_signing_date: ~D[2021-01-21],
            debtor_name: "Debtor Name",
            debtor_address: %{town_name: "Bern", country: "CH"},
            debtor_iban: "CH7280005000088877766",
            debtor_bic: "RAIFCH22005",
            remittance_information: "Unstructured Remittance Information"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Pmt-ID-002",
          %{
            end_to_end_id: "EndToEndId-0001",
            amount: 100.01,
            mandate_id: "Mandate-Id-01",
            mandate_signing_date: ~D[2021-01-21],
            debtor_name: "Debtor Name",
            debtor_address: %{town_name: "Bern", country: "CH"},
            debtor_iban: "CH7280005000088877766",
            debtor_bic: "RAIFCH22005",
            remittance_information: "Unstructured Remittance Information"
          }
        )

      direct_debit =
        ExSepa.DirectDebit.add_transaction_information(
          direct_debit,
          "Pmt-ID-001",
          %{
            end_to_end_id: "EndToEndId-0002",
            amount: 22.22,
            mandate_id: "Mandate-Id-02",
            mandate_signing_date: ~D[2022-02-22],
            debtor_name: "Debtor Name",
            debtor_address: %{town_name: "Bern", country: "CH"},
            debtor_iban: "CH7280005000088877766",
            debtor_bic: "RAIFCH22005",
            remittance_information: "Unstructured Remittance Information"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-002",
               %{
                 end_to_end_id: "EndToEndId-0002",
                 amount: 22.22,
                 mandate_id: "Mandate-Id-02",
                 mandate_signing_date: ~D[2022-02-22],
                 debtor_name: "Debtor Name",
                 debtor_address: %{town_name: "Bern", country: "CH"},
                 debtor_iban: "CH7280005000088877766",
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             ) == %ExSepa.DirectDebit{
               group_header: %ExSepa.GroupHeader{
                 initiating_party_name: "Initiating Party",
                 msg_id: "Msg-ID-001"
               },
               payment_information: [
                 %ExSepa.PaymentInformation{
                   creditor_address: nil,
                   creditor_bic: "",
                   creditor_iban: "DE87200500001234567890",
                   creditor_id: "CIDZZZ00000001",
                   creditor_name: "Creditor Name",
                   due_date: date |> Date.add(1),
                   payment_id: "Pmt-ID-002",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0002",
                       amount: 22.22,
                       mandate_id: "Mandate-Id-02",
                       mandate_signing_date: ~D[2022-02-22],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     },
                     %ExSepa.TransactionInformation{
                       amount: 100.01,
                       debtor_address: %ExSepa.Address{
                         building_name: nil,
                         building_number: nil,
                         country: "CH",
                         country_sub_division: nil,
                         department: nil,
                         district_name: nil,
                         floor: nil,
                         post_box: nil,
                         post_code: nil,
                         room: nil,
                         street_name: nil,
                         sub_department: nil,
                         town_location_name: nil,
                         town_name: "Bern"
                       },
                       debtor_bic: "RAIFCH22005",
                       debtor_iban: "CH7280005000088877766",
                       debtor_name: "Debtor Name",
                       end_to_end_id: "EndToEndId-0001",
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 },
                 %ExSepa.PaymentInformation{
                   payment_id: "Pmt-ID-001",
                   due_date: date,
                   creditor_id: "CIDZZZ00000001",
                   creditor_name: "Creditor Name",
                   creditor_address: nil,
                   creditor_iban: "DE87200500001234567890",
                   creditor_bic: "",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0002",
                       amount: 22.22,
                       mandate_id: "Mandate-Id-02",
                       mandate_signing_date: ~D[2022-02-22],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     },
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_address: %ExSepa.Address{
                         department: nil,
                         sub_department: nil,
                         street_name: nil,
                         building_number: nil,
                         building_name: nil,
                         floor: nil,
                         post_box: nil,
                         room: nil,
                         post_code: nil,
                         town_name: "Bern",
                         town_location_name: nil,
                         district_name: nil,
                         country_sub_division: nil,
                         country: "CH"
                       },
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate a second Transaction Information - fail: no such payment_id" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          msg_id: "Msg-ID-001",
          initiating_party_name: "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            payment_id: "Pmt-ID-001",
            due_date: date,
            creditor_id: "CIDZZZ00000001",
            creditor_name: "Creditor Name",
            creditor_iban: "DE87200500001234567890"
          }
        )

      assert_raise ExSepa.TransactionInformationError,
                   "payment_id: Pmt-ID-002 does not exists in payment information",
                   fn ->
                     ExSepa.DirectDebit.add_transaction_information(
                       direct_debit,
                       "Pmt-ID-002",
                       %{
                         end_to_end_id: "EndToEndId-0001",
                         amount: 100.01,
                         mandate_id: "Mandate-Id-01",
                         mandate_signing_date: ~D[2021-01-21],
                         debtor_name: "Debtor Name",
                         debtor_iban: "CH7280005000088877766",
                         debtor_bic: "RAIFCH22005",
                         remittance_information: "Unstructured Remittance Information"
                       }
                     )
                   end
    end
  end

  describe "SEPA-DirectDebit XML" do
    test "Generate XML without BIC" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      endtoendid = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      dd = ExSepa.DirectDebit.new(%{msg_id: msg_id, initiating_party_name: i_party})

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: pmt_id,
               due_date: date,
               creditor_id: "DE00ZZZ00099999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %{
                 end_to_end_id: endtoendid,
                 amount: price,
                 mandate_id: mndt_id,
                 mandate_signing_date: mndt_date,
                 debtor_name: debtor_name,
                 debtor_iban: debtor_iban,
                 remittance_information: "Unstructured Remittance Information"
               }
             )
             |> ExSepa.DirectDebit.to_xml() ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>OOFF</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <Othr>\n            <Id>NOTPROVIDED</Id>\n          </Othr>\n        </FinInstnId>\n      </CdtrAgt>\n      <ChrgBr>SLEV</ChrgBr>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE00ZZZ00099999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{endtoendid}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <Othr>\n              <Id>NOTPROVIDED</Id>\n            </Othr>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>Unstructured Remittance Information</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end

    test "Generate XML 2" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      endtoendid = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      dd = ExSepa.DirectDebit.new(%{msg_id: msg_id, initiating_party_name: i_party})

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               payment_id: pmt_id,
               due_date: date,
               creditor_id: "DE00ZZZ00099999999",
               creditor_name: creditor_name,
               creditor_iban: creditor_iban,
               creditor_bic: "BANKDEFFXXX"
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %{
                 end_to_end_id: endtoendid,
                 amount: price,
                 mandate_id: mndt_id,
                 mandate_signing_date: mndt_date,
                 debtor_name: debtor_name,
                 debtor_iban: debtor_iban,
                 debtor_bic: "RAIFCH22005",
                 remittance_information: "Unstructured Remittance Information"
               }
             )
             |> ExSepa.DirectDebit.to_xml() ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>OOFF</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <BICFI>BANKDEFFXXX</BICFI>\n        </FinInstnId>\n      </CdtrAgt>\n      <ChrgBr>SLEV</ChrgBr>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE00ZZZ00099999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{endtoendid}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <BICFI>RAIFCH22005</BICFI>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>Unstructured Remittance Information</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end

    test "Generate XML 3" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

      x = 0
      # 1 Einzeltransaktionen benötigen ca. 55,3 ms
      # 10 Einzeltransaktionen benötigen ca. 71,3 ms
      # 100 Einzeltransaktionen benötigen ca. 0,2 s
      # 500 Einzeltransaktionen benötigen ca. 0,6 s
      # 1.000 Einzeltransaktionen benötigen ca. 1,4 s
      # 2.000 Einzeltransaktionen benötigen ca. 3,5 s
      # 3.000 Einzeltransaktionen benötigen ca. 5,4 s
      # 4.000 Einzeltransaktionen benötigen ca. 6,5 s
      # 5.000 Einzeltransaktionen benötigen ca. 7,6 s
      # 10.000 Einzeltransaktionen benötigen ca. 17 s
      # 20.000 Einzeltransaktionen benötigen ca. 43 s
      # 30.000 Einzeltransaktionen benötigen ca. 1 min. und 21 s
      # 40.000 Einzeltransaktionen benötigen ca. 1 min. und 55 s
      # 50.000 Einzeltransaktionen benötigen ca. 2 min. und 33 s
      # 100.000 Einzeltransaktionen benötigen ca. 7 min. und 51 s
      trans_infos =
        for n <- 0..x do
          endtoendid = Faker.Gov.Us.ssn()
          price = Faker.Commerce.price()
          mndt_id = Faker.Gov.Us.ein()
          mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
          debtor_name = Faker.Person.name()
          debtor_iban = Faker.Code.Iban.iban(Enum.drop(get_eea_iban_country_codes(), -1))

          {:ok, ti} =
            ExSepa.TransactionInformation.new(%{
              end_to_end_id: endtoendid,
              amount: price,
              mandate_id: mndt_id,
              mandate_signing_date: mndt_date,
              debtor_name: debtor_name,
              debtor_iban: debtor_iban,
              remittance_information: "Unstructured Remittance Information #{n}"
            })

          ti
        end

      direct_debit =
        ExSepa.DirectDebit.new(%{msg_id: msg_id, initiating_party_name: i_party})

      xml =
        direct_debit
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: pmt_id,
          due_date: date,
          creditor_id: "DE00ZZZ00099999999",
          creditor_name: creditor_name,
          creditor_iban: creditor_iban,
          transaction_information: trans_infos
        })
        |> ExSepa.DirectDebit.to_xml()

      {:ok, file} = File.open("./pain.test_#{x + 1}.xml", [:write])
      IO.binwrite(file, xml)
      File.close(file)
    end

    test "Generate XML 4" do
      direct_debit =
        ExSepa.DirectDebit.new(%{msg_id: "Msg-ID-003", initiating_party_name: "Initiating Party"})

      xml =
        direct_debit
        |> ExSepa.DirectDebit.add_payment_information(%{
          payment_id: "Payment-ID-0003",
          due_date: Date.utc_today() |> Date.add(5),
          creditor_id: "DE00ZZZ00099999999",
          creditor_name: "Creditor Name",
          creditor_iban: "DE87200500001234567890"
        })
        |> ExSepa.DirectDebit.add_transaction_information(
          "Payment-ID-0003",
          %{
            end_to_end_id: "EndToEndId-0003",
            amount: 100.01,
            mandate_id: "Mandate-Id-03",
            mandate_signing_date: ~D[2023-03-23],
            debtor_name: "Debtor Name",
            debtor_iban: "AD6510434606G73BA76MI9TE",
            debtor_bic: "CASBADADXXX",
            debtor_address: %{town_name: "Andorra la Vella", country: "AD"},
            remittance_information: "Invoice Example 0003"
          }
        )
        |> ExSepa.DirectDebit.to_xml()

      {:ok, file} = File.open("./pain.test_dd.xml", [:write])
      IO.binwrite(file, xml)
      File.close(file)

      {:ok, xsddoc} = File.read(Path.expand("./lib/ex_sepa/pain.008.001.08_GBIC_4.xsd"))

      {:ok, model} = :erlsom.compile_xsd(xsddoc)

      assert match?({:ok, _out, _rest}, :erlsom.scan(xml, model)), ":ok"
    end
  end
end
