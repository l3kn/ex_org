defmodule ExOrgTest do
  use ExUnit.Case
  doctest ExOrg

  test "greets the world" do
    assert ExOrg.hello() == :world
  end
end
