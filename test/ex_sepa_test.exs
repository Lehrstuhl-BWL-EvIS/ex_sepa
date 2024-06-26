defmodule ExSepaTest do
  use ExUnit.Case, async: false
  import ExSepa, only: [get_country_codes: 0]
  doctest ExSepa.DirectDebit

  describe "ExSepa.DirectDebit new Initiation Message" do
    test "Generate a new direct debit" do
      assert ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party") ==
               %ExSepa.CustomerDirectDebitInitiationV08{
                 group_header: %ExSepa.GroupHeader{
                   msg_id: "Msg-ID-001",
                   initiating_party_name: "Initiating Party"
                 },
                 payment_information: nil,
                 transaction_information: nil
               }
    end

    test "Generate a new direct debit - fail: msg_id is not a String" do
      assert ExSepa.DirectDebit.new(<<0xFFFF::16>>, "Initiating Party") ==
               {:error, "msg_id: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail: initiating_party_name is not a String" do
      assert ExSepa.DirectDebit.new("001", <<0xFFFF::16>>) ==
               {:error, "initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail on msg_id" do
      assert ExSepa.DirectDebit.new(000_100, "Ein Fußballclub") ==
               {:error, "Parameters must be strings. - msg_id: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail on initiating_party_name" do
      assert ExSepa.DirectDebit.new("Msg-ID-000100", 345) ==
               {:error,
                "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail on msg_id and initiating_party_name" do
      assert ExSepa.DirectDebit.new(00450, 123_456) ==
               {:error,
                "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit - fail: on msg_id length" do
      assert ExSepa.DirectDebit.new(
               "0123456789012345678901234567890123456789",
               "Initiating Party"
             ) ==
               {:error, "msg_id: maximum length of 35 characters"}
    end

    test "Generate a new direct debit - fail: on initiating_party_name length" do
      assert ExSepa.DirectDebit.new(
               "ID-0001",
               "The name of the person who has initiated the call is too long to be entered in this field."
             ) ==
               {:error, "initiating_party_name: maximum length of 70 characters"}
    end
  end

  describe "ExSepa.DirectDebit new Payment Information" do
    test "Generate a new Payment Information" do
      date = Date.utc_today() |> Date.add(5)
      direct_debit = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")

      assert ExSepa.DirectDebit.add_payment_information(
               direct_debit,
               "Pmt-ID-001",
               date,
               "DE00ZZZ00099999999",
               "Creditor Name",
               "DE87200500001234567890",
               "BANKDEFFXXX",
               :OneOff
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
                   sequence_type: :OneOff
                 }
               ],
               transaction_information: nil
             }
    end
  end

  describe "ExSepa.DirectDebit new Transaction Information" do
    test "Generate a new Transaction Information 1" do
      date = Date.utc_today() |> Date.add(3)
      direct_debit = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          "Pmt-ID-001",
          date,
          "DE00ZZZ00099999999",
          "Creditor Name",
          "DE87200500001234567890",
          "BANKDEFFXXX"
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               "EndToEndId-0001",
               100.01,
               "Mandate-Id-01",
               ~D[2021-01-21],
               "Debtor Name",
               "CH7280005000088877766",
               "RAIFCH22005",
               "Unstructured Remittance Information"
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
                   sequence_type: :First
                 }
               ],
               transaction_information: [
                 {"Pmt-ID-001",
                  %ExSepa.TransactionInformation{
                    end_to_end_id: "EndToEndId-0001",
                    amount: 100.01,
                    mandate_id: "Mandate-Id-01",
                    mandate_signing_date: ~D[2021-01-21],
                    debtor_name: "Debtor Name",
                    debtor_iban: "CH7280005000088877766",
                    debtor_bic: "RAIFCH22005",
                    remittance_information: "Unstructured Remittance Information"
                  }}
               ]
             }
    end

    test "Generate a new Transaction Information 2" do
      date = Date.utc_today() |> Date.add(3)
      direct_debit = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          "Pmt-ID-001",
          date,
          "DE00ZZZ00099999999",
          "Creditor Name",
          "DE87200500001234567890",
          "BANKDEFFXXX"
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
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
                   sequence_type: :First
                 }
               ],
               transaction_information: [
                 {"Pmt-ID-001",
                  %ExSepa.TransactionInformation{
                    end_to_end_id: "EndToEndId-0001",
                    amount: 100.01,
                    mandate_id: "Mandate-Id-01",
                    mandate_signing_date: ~D[2021-01-21],
                    debtor_name: "Debtor Name",
                    debtor_iban: "CH7280005000088877766",
                    debtor_bic: "RAIFCH22005",
                    remittance_information: "Unstructured Remittance Information"
                  }}
               ]
             }
    end

    test "Generate a new Transaction Information 3" do
      date = Date.utc_today() |> Date.add(3)

      dd = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(
               "Pmt-ID-001",
               date,
               "DE00ZZZ00099999999",
               "Creditor Name",
               "DE87200500001234567890",
               "BANKDEFFXXX"
             )
             |> ExSepa.DirectDebit.add_transaction_information(
               "Pmt-ID-001",
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
                   sequence_type: :First
                 }
               ],
               transaction_information: [
                 {"Pmt-ID-001",
                  %ExSepa.TransactionInformation{
                    end_to_end_id: "EndToEndId-0001",
                    amount: 100.01,
                    mandate_id: "Mandate-Id-01",
                    mandate_signing_date: ~D[2021-01-21],
                    debtor_name: "Debtor Name",
                    debtor_iban: "CH7280005000088877766",
                    debtor_bic: "RAIFCH22005",
                    remittance_information: "Unstructured Remittance Information"
                  }}
               ]
             }
    end

    test "Generate a new Transaction Information 4" do
      date = Date.utc_today() |> Date.add(3)
      direct_debit = ExSepa.DirectDebit.new("Msg-ID-001", "Initiating Party")

      direct_debit =
        ExSepa.DirectDebit.add_payment_information(
          direct_debit,
          "Pmt-ID-001",
          date,
          "DE00ZZZ00099999999",
          "Creditor Name",
          "DE87200500001234567890"
        )

      assert ExSepa.DirectDebit.add_transaction_information(
               direct_debit,
               "Pmt-ID-001",
               "EndToEndId-0001",
               100.01,
               "Mandate-Id-01",
               ~D[2021-01-21],
               "Debtor Name",
               "CH7280005000088877766",
               "RAIFCH22005",
               "Unstructured Remittance Information"
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
                   sequence_type: :First
                 }
               ],
               transaction_information: [
                 {"Pmt-ID-001",
                  %ExSepa.TransactionInformation{
                    end_to_end_id: "EndToEndId-0001",
                    amount: 100.01,
                    mandate_id: "Mandate-Id-01",
                    mandate_signing_date: ~D[2021-01-21],
                    debtor_name: "Debtor Name",
                    debtor_iban: "CH7280005000088877766",
                    debtor_bic: "RAIFCH22005",
                    remittance_information: "Unstructured Remittance Information"
                  }}
               ]
             }
    end
  end

  describe "SEPA-DirectDebit XML" do
    test "Generate XML without BIC" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      # IO.inspect(msg_id, label: "msg_id")
      # IO.inspect(i_party, label: "i_party")

      # Faker.Util.format()
      # Faker.Util.join(4, "-", fn -> Faker.format("####") end)

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(get_country_codes())

      # IO.inspect(pmt_id, label: "pmt_id")
      # IO.inspect(date, label: "date")
      # IO.inspect(creditor_name, label: "cName")
      # IO.inspect(creditor_iban, label: "cIban")

      endtoendid = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_country_codes())

      # IO.inspect(endtoendid, label: "endtoendid")
      # IO.inspect(price, label: "price")
      # IO.inspect(mndt_id, label: "mndt_id")
      # IO.inspect(mndt_date, label: "mndt_date")
      # IO.inspect(debtor_name, label: "debtor_name")
      # IO.inspect(debtor_iban, label: "debtor_iban")

      dd = ExSepa.DirectDebit.new(msg_id, i_party)

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(
               pmt_id,
               date,
               "DE00ZZZ00099999999",
               creditor_name,
               creditor_iban,
               "BANKDEFFXXX"
             )
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %ExSepa.TransactionInformation{
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
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>FRST</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <BICFI>BANKDEFFXXX</BICFI>\n        </FinInstnId>\n      </CdtrAgt>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE00ZZZ00099999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{endtoendid}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <BICFI>RAIFCH22005</BICFI>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>Unstructured Remittance Information</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end

    test "Generate XML 2" do
      msg_id = Faker.Gov.Us.ein()
      i_party = Faker.Person.name()

      # IO.inspect(msg_id, label: "msg_id")
      # IO.inspect(i_party, label: "i_party")

      # Faker.Util.format()
      # Faker.Util.join(4, "-", fn -> Faker.format("####") end)

      pmt_id = Faker.Gov.Us.ein()
      date = Date.utc_today() |> Date.add(3)
      creditor_name = Faker.Team.name()
      creditor_iban = Faker.Code.Iban.iban(get_country_codes())

      # IO.inspect(pmt_id, label: "pmt_id")
      # IO.inspect(date, label: "date")
      # IO.inspect(creditor_name, label: "cName")
      # IO.inspect(creditor_iban, label: "cIban")

      endtoendid = Faker.Gov.Us.ssn()
      price = Faker.Commerce.price()
      mndt_id = Faker.Gov.Us.ein()
      mndt_date = Faker.Date.backward(Faker.Random.Elixir.random_between(60, 900))
      debtor_name = Faker.Person.name()
      debtor_iban = Faker.Code.Iban.iban(get_country_codes())

      # IO.inspect(endtoendid, label: "endtoendid")
      # IO.inspect(price, label: "price")
      # IO.inspect(mndt_id, label: "mndt_id")
      # IO.inspect(mndt_date, label: "mndt_date")
      # IO.inspect(debtor_name, label: "debtor_name")
      # IO.inspect(debtor_iban, label: "debtor_iban")

      dd = ExSepa.DirectDebit.new(msg_id, i_party)

      assert dd
             |> ExSepa.DirectDebit.add_payment_information(
               pmt_id,
               date,
               "DE00ZZZ00099999999",
               creditor_name,
               creditor_iban
             )
             |> ExSepa.DirectDebit.add_transaction_information(
               pmt_id,
               %ExSepa.TransactionInformation{
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
               "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<Document xmlns=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"urn:iso:std:iso:20022:tech:xsd:pain.008.001.08 pain.008.001.08.xsd\">\n  <CstmrDrctDbtInitn>\n    <GrpHdr>\n      <MsgId>#{msg_id}</MsgId>\n      <CreDtTm>#{DateTime.to_iso8601(DateTime.utc_now(:second))}</CreDtTm>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <InitgPty>\n        <Nm>#{i_party}</Nm>\n      </InitgPty>\n    </GrpHdr>\n    <PmtInf>\n      <PmtInfId>#{pmt_id}</PmtInfId>\n      <PmtMtd>DD</PmtMtd>\n      <NbOfTxs>1</NbOfTxs>\n      <CtrlSum>#{price}</CtrlSum>\n      <PmtTpInf>\n        <SvcLvl>\n          <Cd>SEPA</Cd>\n        </SvcLvl>\n        <LclInstrm>\n          <Cd>CORE</Cd>\n        </LclInstrm>\n        <SeqTp>FRST</SeqTp>\n      </PmtTpInf>\n      <ReqdColltnDt>#{date}</ReqdColltnDt>\n      <Cdtr>\n        <Nm>#{creditor_name}</Nm>\n      </Cdtr>\n      <CdtrAcct>\n        <Id>\n          <IBAN>#{creditor_iban}</IBAN>\n        </Id>\n      </CdtrAcct>\n      <CdtrAgt>\n        <FinInstnId>\n          <Othr>\n            <Id>NOTPROVIDED</Id>\n          </Othr>\n        </FinInstnId>\n      </CdtrAgt>\n      <CdtrSchmeId>\n        <Id>\n          <PrvtId>\n            <Othr>\n              <Id>DE00ZZZ00099999999</Id>\n              <SchmeNm>\n                <Prtry>SEPA</Prtry>\n              </SchmeNm>\n            </Othr>\n          </PrvtId>\n        </Id>\n      </CdtrSchmeId>\n      <DrctDbtTxInf>\n        <PmtId>\n          <EndToEndId>#{endtoendid}</EndToEndId>\n        </PmtId>\n        <InstdAmt Ccy=\"EUR\">#{price}</InstdAmt>\n        <DrctDbtTx>\n          <MndtRltdInf>\n            <MndtId>#{mndt_id}</MndtId>\n            <DtOfSgntr>#{mndt_date}</DtOfSgntr>\n          </MndtRltdInf>\n        </DrctDbtTx>\n        <DbtrAgt>\n          <FinInstnId>\n            <BICFI>RAIFCH22005</BICFI>\n          </FinInstnId>\n        </DbtrAgt>\n        <Dbtr>\n          <Nm>#{debtor_name}</Nm>\n        </Dbtr>\n        <DbtrAcct>\n          <Id>\n            <IBAN>#{debtor_iban}</IBAN>\n          </Id>\n        </DbtrAcct>\n        <RmtInf>\n          <Ustrd>Unstructured Remittance Information</Ustrd>\n        </RmtInf>\n      </DrctDbtTxInf>\n    </PmtInf>\n  </CstmrDrctDbtInitn>\n</Document>"
    end
  end
end
