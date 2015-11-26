defmodule Escenario1Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, [])
    {:ok, plataforma: plataforma}
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

  test "escenario1", %{plataforma: plataforma} do
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")

    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    # Notificacion a los clientes de la nueva subasta

    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    # Notificacion a los clientes de la oferta

    :timer.sleep(1000)
    # Notificacion a los clientes de la subasta finalizada

    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 15
    assert subasta.duration == 1
    assert subasta.offerer == "john snow"
  end
end
