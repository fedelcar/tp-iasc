defmodule Escenario1Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    {:ok, subasta} = Subasta.start_link(ets, [])
    {:ok, subasta: subasta}
  end


# Un comprador A se registra en el sistema,  expresando así su interés por participar en subastas. Indica al menos:
#   un nombre
#   una forma de contacto
# Otro comprador B se registra de igual forma en el sistema
# Un vendedor crea una subasta, con la siguiente información
#   Un título
#   Un precio base (que puede ser cero)
#   La duración máxima de la subasta
# El sistema publica el título y expiración de la subasta a todos los compradores (en este caso, a los compradores A y B).
# El comprador A publica un precio X
#   El sistema le notifica que su oferta fue aceptada
#   los demás compradores (B en este caso) son notificados de un nuevo precio
# Al cumplirse el timeout,
#   la subasta cierra,
#   Se adjudica a A como el comprador, y se le notifica apropiadamente
#   B es notificado de la finalización de la subasta y de que no le fue adjudicada

  test "escenario1", %{subasta: subasta} do
    miguel = Subasta.create(subasta, {{"miguel", :comprador}, {"miguel@miguel.miguel"}})
    jorge = Subasta.create(subasta, {{"jorge", :comprador}, {"jorge@jorge.jorge"}})

    Subasta.create(subasta, {{"vendo auto", :subasta}, {10, 3, nil}}) # missing notification to al buyers

    Subasta.ofertar(subasta, "vendo auto", 15, jorge) # assert that this offer is ok

    :timer.sleep(3000)
    # assert that bidding finished
    assert {:ok, {{"vendo auto", :subasta}, {17, 3, anibal}}} = Subasta.lookup(subasta, {"vendo auto", :subasta})
    # assert notification to winner and losers
  end
end
