defmodule Escenario3Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    {:ok, subasta} = Subasta.start_link(ets, [])
    {:ok, subasta: subasta}
  end

# Similar a los escenarios anteriores, pero el vendedor cancela la subasta antes de la expiración
# de la subasta y adjudicación del ganador. En este caso, obviamente, nadie gana la subasta,
# y todos los compradores son notificados.

  test "escenario3", %{subasta: subasta} do
    miguel = Subasta.create(subasta, {{"miguel", :comprador}, {"miguel@miguel.miguel"}})
    jorge = Subasta.create(subasta, {{"jorge", :comprador}, {"jorge@jorge.jorge"}})
    anibal = Subasta.create(subasta, {{"anibal", :comprador}, {"anibal@anibal.anibal"}})

    Subasta.create(subasta, {{"vendo auto", :subasta}, {10, 3, nil}}) # missing notification to all buyers

    Subasta.ofertar(subasta, "vendo auto", 15, jorge) # assert offer accepted
    Subasta.ofertar(subasta, "vendo auto", 17, anibal) # assert offer accepted

    Subasta.cancelar(subasta, "vendo auto") # this should cancel the bidding and notify all buyers

    # assert notification to everyone
  end
end
