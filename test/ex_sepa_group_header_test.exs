defmodule ExSepaGroupHeaderTest do
  use ExUnit.Case, async: true
  doctest ExSepa.GroupHeader

  describe "ExSepa.GroupHeader.new()" do
    test ":ok" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "Msg-ID-000100",
               initiating_party_name: "Example club"
             }) ==
               {:ok,
                %ExSepa.GroupHeader{
                  msg_id: "Msg-ID-000100",
                  initiating_party_name: "Example club"
                }}
    end

    test "error: key missing msg_id" do
      assert ExSepa.GroupHeader.new(%{
               id: "Msg-ID-000100",
               initiating_party_name: "Gymnastics & sports club"
             }) ==
               {:error, "missing keys: [:msg_id]"}
    end

    test "error: key missing initiating_party_name" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "Msg-ID-000100",
               initiating_party: "Gymnastics & sports club"
             }) ==
               {:error, "missing keys: [:initiating_party_name]"}
    end

    test "error: key missing msg_id and initiating_party_name" do
      assert ExSepa.GroupHeader.new(%{
               msg: "Msg-ID-000100",
               initiating_party: "Gymnastics & sports club"
             }) ==
               {:error, "missing keys: [:msg_id, :initiating_party_name]"}
    end

    test "ok: initiating_party_name ampersand" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "Msg-ID-000100",
               initiating_party_name: "Gymnastics & sports club"
             }) ==
               {:ok,
                %ExSepa.GroupHeader{
                  msg_id: "Msg-ID-000100",
                  initiating_party_name: "Gymnastics + sports club"
                }}
    end

    test "ok: initiating_party_name german Fußbalclub" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "Msg-ID-000100",
               initiating_party_name: "Fußbalclub"
             }) ==
               {:ok,
                %ExSepa.GroupHeader{msg_id: "Msg-ID-000100", initiating_party_name: "Fusbalclub"}}
    end

    test "error: msg_id is not a string 1" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: <<0xFFFF::16>>,
               initiating_party_name: "Initiating Party"
             }) ==
               {:error, "msg_id: must be UTF-8 encoded binary"}
    end

    test "error: msg_id is not a string 2" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: 000_100,
               initiating_party_name: "Initiating Party"
             }) ==
               {:error, "Parameters must be strings. - msg_id: must be UTF-8 encoded binary"}
    end

    test "error: initiating_party_name is not a String 1" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "001",
               initiating_party_name: <<0xFFFF::16>>
             }) ==
               {:error, "initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "error: initiating_party_name is not a String 2" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "Msg-ID-000100",
               initiating_party_name: 345
             }) ==
               {:error,
                "Parameters must be strings. - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "error: msg_id and initiating_party_name" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: 00450,
               initiating_party_name: 123_456
             }) ==
               {:error,
                "Parameters must be strings. - msg_id: must be UTF-8 encoded binary - initiating_party_name: must be UTF-8 encoded binary"}
    end

    test "error: on msg_id length" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "0123456789012345678901234567890123456789",
               initiating_party_name: "Initiating Party"
             }) ==
               {:error, "msg_id: Maximum length of 35 characters"}
    end

    test "error: on initiating_party_name length" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "ID-0001",
               initiating_party_name:
                 "The name of the person who has initiated the call is too long to be entered in this field."
             }) ==
               {:error, "initiating_party_name: Maximum length of 70 characters"}
    end

    test "latin character set 1" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "MSG-ID-0001",
               initiating_party_name: "René Rast"
             }) ==
               {:error,
                "initiating_party_name: These characters are not part of the pattern test: é"}
    end

    test "latin character set 2" do
      assert ExSepa.GroupHeader.new(%{
               msg_id: "MSG-&-0001",
               initiating_party_name: "René Rast"
             }) ==
               {:error,
                "initiating_party_name: These characters are not part of the pattern test: é"}
    end
  end
end
