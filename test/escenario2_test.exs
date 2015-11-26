defmodule Escenario2Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    {:ok, subasta} = Subasta.start_link(ets, [])
    {:ok, subasta: subasta}
  end

  test "escenario2", %{subasta: subasta} do
    miguel = Subasta.create(subasta, {{"miguel", :comprador}, {"miguel@miguel.miguel"}})
    jorge = Subasta.create(subasta, {{"jorge", :comprador}, {"jorge@jorge.jorge"}})
    anibal = Subasta.create(subasta, {{"anibal", :comprador}, {"anibal@anibal.anibal"}})

    Subasta.create(subasta, {{"vendo auto", :subasta}, {10, 3, nil}}) # missing notification to al buyers

    Subasta.ofertar(subasta, "vendo auto", 15, jorge) # assert offer accepted
    Subasta.ofertar(subasta, "vendo auto", 12, anibal)  # assert offer rejected
    Subasta.ofertar(subasta, "vendo auto", 17, anibal) # assert offer accepted

    :timer.sleep(3000)
    # assert that bidding finished
    assert {:ok, {{"vendo auto", :subasta}, {17, 3, anibal}}} = Subasta.lookup(subasta, {"vendo auto", :subasta})
    # assert notification to winner and losers
  end
end
