defmodule ExSepaGroupHeaderTest do
  use ExUnit.Case, async: false
  doctest ExSepa.GroupHeader

  describe "ExSepa.GroupHeader new" do
    test "Generate a new direct debit group header" do
      assert ExSepa.GroupHeader.new("Msg-ID-000100", "Ein Fußballclub") ==
               {:ok, %ExSepa.GroupHeader{msgId: "Msg-ID-000100", initgPtyNm: "Ein Fußballclub"}}
    end

    test "Generate a new direct debit group header fail on msgId" do
      assert ExSepa.GroupHeader.new(000_100, "Ein Fußballclub") ==
               {:error,
                {ExSepa.GroupHeader,
                 "Parameters must be strings. - msgId: must be UTF-8 encoded binary"}}
    end

    test "Generate a new direct debit group header fail on initgPtyNm" do
      assert ExSepa.GroupHeader.new("Msg-ID-000100", 345) ==
               {:error,
                {ExSepa.GroupHeader,
                 "Parameters must be strings. - initgPtyNm: must be UTF-8 encoded binary"}}
    end

    test "Generate a new direct debit group header fail on msgId and initgPtyNm" do
      assert ExSepa.GroupHeader.new(00450, 123_456) ==
               {:error,
                {ExSepa.GroupHeader,
                 "Parameters must be strings. - msgId: must be UTF-8 encoded binary - initgPtyNm: must be UTF-8 encoded binary"}}
    end
  end
end
