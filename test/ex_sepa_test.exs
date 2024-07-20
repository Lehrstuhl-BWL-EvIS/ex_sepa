defmodule ExSepaTest do
  use ExUnit.Case, async: false
  import ExSepa, only: [get_iban_country_codes: 0]
  doctest ExSepa.DirectDebit

  describe "ExSepa.DirectDebit new Initiation Message" do
    test "Generate a new direct debit" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => "Msg-ID-001",
               "initiating_party_name" => "Initiating Party"
             }) ==
               %ExSepa.CustomerDirectDebitInitiationV08{
                 group_header: %ExSepa.GroupHeader{
                   msg_id: "Msg-ID-001",
                   initiating_party_name: "Initiating Party"
                 },
                 payment_information: nil
               }
    end

    test "Generate a new direct debit - fail: msg_id is not a String" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => <<0xFFFF::16>>,
               "initiating_party_name" => "Initiating Party"
             }) ==
               {:error, "msg_id: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail: initiating_party_name is not a String" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => "001",
               "initiating_party_name" => <<0xFFFF::16>>
             }) ==
               {:error, "initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail on msg_id" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => 000_001,
               "initiating_party_name" => "Initiating Party"
             }) ==
               {:error, "Parameters must be strings. - msg_id: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail on initiating_party_name" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => "Msg-ID-000100",
               "initiating_party_name" => 345
             }) ==
               {:error,
                "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail on msg_id and initiating_party_name" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => 00450,
               "initiating_party_name" => 123_456
             }) ==
               {:error,
                "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail: on msg_id length" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => "0123456789012345678901234567890123456789",
               "initiating_party_name" => "Initiating Party"
             }) ==
               {:error, "msg_id: Maximum length of 35 characters"}
    end

    test "Generate a new direct debit - fail: on initiating_party_name length" do
      assert ExSepa.DirectDebit.new(%{
               "msg_id" => "ID-0001",
               "initiating_party_name" =>
                 "The name of the person who has initiated the call is too long to be entered in this field."
             }) ==
               {:error, "initiating_party_name: Maximum length of 70 characters"}
    end
  end

  describe "ExSepa.DirectDebit new Payment Information" do
    test "Generate a new Payment Information - :ok" do
      date = Date.utc_today() |> Date.add(5)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      assert ExSepa.DirectDebit.add_payment_information(
               direct_debit,
               %{
                 "payment_id" => "Pmt-ID-001",
                 "due_date" => date,
                 "creditor_id" => "DE00ZZZ00099999999",
                 "creditor_name" => "Creditor Name",
                 "creditor_iban" => "DE87200500001234567890",
                 "creditor_bic" => "BANKDEFFXXX"
               }
             ) == %ExSepa.CustomerDirectDebitInitiationV08{
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
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      assert direct_debit
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => "Pmt-ID-001",
               "due_date" => date,
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => "Creditor Name",
               "creditor_iban" => "DE87200500001234567890"
             })
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => "Pmt-ID-002",
               "due_date" => date |> Date.add(2),
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => "Creditor Name",
               "creditor_iban" => "DE87200500001234567890"
             }) == %ExSepa.CustomerDirectDebitInitiationV08{
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
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      assert direct_debit
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => "Pmt-ID-001",
               "due_date" => date,
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => "Creditor Name",
               "creditor_iban" => "DE87200500001234567890"
             })
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => "Pmt-ID-001",
               "due_date" => date,
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => "Creditor Name",
               "creditor_iban" => "DE87200500001234567890"
             }) == {:error, "payment_id: Pmt-ID-001 already exists"}
    end
  end

  describe "ExSepa.DirectDebit new Transaction Information" do
    test "Generate a new Transaction Information 1" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            "payment_id" => "Pmt-ID-001",
            "due_date" => date,
            "creditor_id" => "CIDZZZ00000001",
            "creditor_name" => "Creditor Name",
            "creditor_iban" => "DE87200500001234567890",
            "creditor_bic" => "BANKDEFFXXX"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               %{
                 "end_to_end_id" => "EndToEndId-0001",
                 "amount" => 100.01,
                 "mandate_id" => "Mandate-Id-01",
                 "mandate_signing_date" => ~D[2021-01-21],
                 "debtor_name" => "Debtor Name",
                 "debtor_iban" => "CH7280005000088877766",
                 "debtor_bic" => "RAIFCH22005",
                 "remittance_information" => "Unstructured Remittance Information"
               }
             ) == %ExSepa.CustomerDirectDebitInitiationV08{
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
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "RAIFCH22005",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "new Transaction Information 2" do
      date = Date.utc_today() |> Date.add(3)

      direct_debit =
        ExSepa.DirectDebit.new(%{
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            "payment_id" => "Pmt-ID-001",
            "due_date" => date,
            "creditor_id" => "DE00ZZZ00099999999",
            "creditor_name" => "Creditor Name",
            "creditor_iban" => "DE87200500001234567890"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               %{
                 "end_to_end_id" => "EndToEndId-0001",
                 "amount" => 100.01,
                 "mandate_id" => "Mandate-Id-01",
                 "mandate_signing_date" => ~D[2021-01-21],
                 "debtor_name" => "Debtor Name",
                 "debtor_iban" => "CH7280005000088877766",
                 "remittance_information" => "Unstructured Remittance Information"
               }
             ) == %ExSepa.CustomerDirectDebitInitiationV08{
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
                   creditor_bic: "",
                   sequence_type: :OneOff,
                   transaction_information: [
                     %ExSepa.TransactionInformation{
                       end_to_end_id: "EndToEndId-0001",
                       amount: 100.01,
                       mandate_id: "Mandate-Id-01",
                       mandate_signing_date: ~D[2021-01-21],
                       debtor_name: "Debtor Name",
                       debtor_iban: "CH7280005000088877766",
                       debtor_bic: "",
                       remittance_information: "Unstructured Remittance Information"
                     }
                   ]
                 }
               ]
             }
    end

    test "Generate a new Transaction Information 3" do
      date = Date.utc_today() |> Date.add(3)

      dd =
        ExSepa.DirectDebit.new(%{
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => "Pmt-ID-001",
               "due_date" => date,
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => "Creditor Name",
               "creditor_iban" => "DE87200500001234567890",
               "creditor_bic" => "BANKDEFFXXX"
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               "Pmt-ID-001",
               %{
                 "end_to_end_id" => "EndToEndId-0001",
                 "amount" => 100.01,
                 "mandate_id" => "Mandate-Id-01",
                 "mandate_signing_date" => ~D[2021-01-21],
                 "debtor_name" => "Debtor Name",
                 "debtor_iban" => "CH7280005000088877766",
                 "debtor_bic" => "RAIFCH22005",
                 "remittance_information" => "Unstructured Remittance Information"
               }
             ) == %ExSepa.CustomerDirectDebitInitiationV08{
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
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            "payment_id" => "Pmt-ID-001",
            "due_date" => date,
            "creditor_id" => "CIDZZZ00000001",
            "creditor_name" => "Creditor Name",
            "creditor_iban" => "DE87200500001234567890"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               %{
                 "end_to_end_id" => "EndToEndId-0001",
                 "amount" => 100.01,
                 "mandate_id" => "Mandate-Id-01",
                 "mandate_signing_date" => ~D[2021-01-21],
                 "debtor_name" => "Debtor Name",
                 "debtor_iban" => "CH7280005000088877766",
                 "debtor_bic" => "RAIFCH22005",
                 "remittance_information" => "Unstructured Remittance Information"
               }
             ) == %ExSepa.CustomerDirectDebitInitiationV08{
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
          "msg_id" => "Msg-ID-001",
          "initiating_party_name" => "Initiating Party"
        })

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          %{
            "payment_id" => "Pmt-ID-001",
            "due_date" => date,
            "creditor_id" => "CIDZZZ00000001",
            "creditor_name" => "Creditor Name",
            "creditor_iban" => "DE87200500001234567890"
          }
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-002",
               %{
                 "end_to_end_id" => "EndToEndId-0001",
                 "amount" => 100.01,
                 "mandate_id" => "Mandate-Id-01",
                 "mandate_signing_date" => ~D[2021-01-21],
                 "debtor_name" => "Debtor Name",
                 "debtor_iban" => "CH7280005000088877766",
                 "debtor_bic" => "RAIFCH22005",
                 "remittance_information" => "Unstructured Remittance Information"
               }
             ) == {:error, "payment_id: Pmt-ID-002 does not exists in payment information"}
    end
  end

  describe "SEPA-DirectDebit XML" do
    test "Generate XML without BIC" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      endtoendid = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      dd = ExSepa.DirectDebit.new(%{"msg_id" => msg_id, "initiating_party_name" => i_party})

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => pmt_id,
               "due_date" => date,
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => creditor_name,
               "creditor_iban" => creditor_iban
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %{
                 "end_to_end_id" => endtoendid,
                 "amount" => price,
                 "mandate_id" => mndt_id,
                 "mandate_signing_date" => mndt_date,
                 "debtor_name" => debtor_name,
                 "debtor_iban" => debtor_iban,
                 "remittance_information" => "Unstructured Remittance Information"
               }
             )
             |> ExSepa.DirectDebit.to_xml() ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>OOFF</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <Othr>\n            <Id>NOTPROVIDED</Id>\n          </Othr>\n        </FinInstnId>\n      </CdtrAgt>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE00ZZZ00099999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{endtoendid}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <Othr>\n              <Id>NOTPROVIDED</Id>\n            </Othr>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>Unstructured Remittance Information</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end

    test "Generate XML 2" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      endtoendid = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_iban_country_codes())

      dd = ExSepa.DirectDebit.new(%{"msg_id" => msg_id, "initiating_party_name" => i_party})

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(%{
               "payment_id" => pmt_id,
               "due_date" => date,
               "creditor_id" => "DE00ZZZ00099999999",
               "creditor_name" => creditor_name,
               "creditor_iban" => creditor_iban,
               "creditor_bic" => "BANKDEFFXXX"
             })
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %{
                 "end_to_end_id" => endtoendid,
                 "amount" => price,
                 "mandate_id" => mndt_id,
                 "mandate_signing_date" => mndt_date,
                 "debtor_name" => debtor_name,
                 "debtor_iban" => debtor_iban,
                 "debtor_bic" => "RAIFCH22005",
                 "remittance_information" => "Unstructured Remittance Information"
               }
             )
             |> ExSepa.DirectDebit.to_xml() ==
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>OOFF</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <BICFI>BANKDEFFXXX</BICFI>\n        </FinInstnId>\n      </CdtrAgt>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE00ZZZ00099999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{endtoendid}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <BICFI>RAIFCH22005</BICFI>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>Unstructured Remittance Information</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end
  end
end
