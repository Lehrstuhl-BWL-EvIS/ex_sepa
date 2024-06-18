defmodule ExSepaTest do
  use ExUnit.Case, async: false
  doctest ExSepa

  test "greets the world" do
    assert ExSepa.hello() == :world
  end
end
