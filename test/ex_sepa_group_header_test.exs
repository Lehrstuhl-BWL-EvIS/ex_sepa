defmodule ExSepaGroupHeaderTest do
  use ExUnit.Case, async: false
  doctest ExSepa.GroupHeader

  describe "ExSepa.GroupHeader new" do
    test "Generate a new direct debit group header - ok" do
      assert ExSepa.GroupHeader.new("Msg-ID-000100", "Ein Fußballclub") ==
               {:ok,
                %ExSepa.GroupHeader{
                  msg_id: "Msg-ID-000100",
                  initiating_party_name: "Ein Fußballclub"
                }}
    end

    test "Generate a new direct debit group header - fail: msg_id is not a String" do
      assert ExSepa.GroupHeader.new(<<0xFFFF::16>>, "Initiating Party") ==
               {:error, "msg_id: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit group header - fail: initiating_party_name is not a String" do
      assert ExSepa.GroupHeader.new("001", <<0xFFFF::16>>) ==
               {:error, "initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit group header fail on msg_id" do
      assert ExSepa.GroupHeader.new(000_100, "Ein Fußballclub") ==
               {:error, "Parameters must be strings. - msg_id: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit group header fail on initiating_party_name" do
      assert ExSepa.GroupHeader.new("Msg-ID-000100", 345) ==
               {:error,
                "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit group header fail on msg_id and initiating_party_name" do
      assert ExSepa.GroupHeader.new(00450, 123_456) ==
               {:error,
                "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "Generate a new direct debit group header - fail: on msg_id length" do
      assert ExSepa.GroupHeader.new(
               "0123456789012345678901234567890123456789",
               "Initiating Party"
             ) ==
               {:error, "msg_id: maximum length of 35 characters"}
    end

    test "Generate a new direct debit group header - fail: on initiating_party_name length" do
      assert ExSepa.GroupHeader.new(
               "ID-0001",
               "The name of the person who has initiated the call is too long to be entered in this field."
             ) ==
               {:error, "initiating_party_name: maximum length of 70 characters"}
    end

    test "latin character set 1" do
      assert ExSepa.GroupHeader.new("MSG-ID-0001", "Stéfan Göttsching") ==
               {:error,
                "initiating_party_name - These characters are not part of the authorised Latin character set: é"}
    end

    test "latin character set 2" do
      assert ExSepa.GroupHeader.new("MSG-§-0001", "Stefan Göttsching") ==
               {:error,
                "msg_id - These characters are not part of the authorised Latin character set: §"}
    end
  end
end
