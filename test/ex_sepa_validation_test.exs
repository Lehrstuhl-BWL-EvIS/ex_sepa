defmodule ExSepaValidationTest do
  use ExUnit.Case, async: true
  doctest ExSepa.Validation

  describe "ExSepa.Validation" do
    test "Test" do
      assert ExSepa.Validation.address_mandatory("DE", "", nil) == :ok
    end
  end
end
