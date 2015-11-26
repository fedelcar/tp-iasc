defmodule SubastasTest do
  use ExUnit.Case

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    {:ok, subasta} = Subasta.start_link(ets, [])
    {:ok, subasta: subasta, ets: ets}
  end

  test "spawns subastas", %{subasta: subasta, ets: ets} do
    assert Subasta.lookup(subasta, {"vendo_auto", :subasta}) == :not_found

    Subasta.create(subasta, {{"vendo_auto", :subasta}, {10, 20}})
    assert {:ok, {{"vendo_auto", :subasta}, {10, 20}}} = Subasta.lookup(subasta, {"vendo_auto", :subasta})
  end

  test "spawns comprador", %{subasta: subasta, ets: ets} do
    assert Subasta.lookup(subasta, {"jorge", :comprador}) == :not_found

    Subasta.create(subasta, {{"miguel", :comprador}, {"miguel@miguel.miguel"}})
    assert {:ok, {{"miguel", :comprador}, {"miguel@miguel.miguel"}}} = Subasta.lookup(subasta, {"miguel", :comprador})
  end
end
