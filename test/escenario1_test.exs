defmodule Escenario1Test do
  use ExUnit.Case

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  setup do
    {:ok, notification} = GenEvent.start_link
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, notification, [])
    GenEvent.add_mon_handler(notification, Forwarder, self())
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

  test "Escenario 1", %{plataforma: plataforma} do

    # Se registran los dos compradores
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")

    # Nueva subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    assert_receive {:new_subasta, "arya stark", "se vende heladera"}
    assert_receive {:new_subasta, "john snow", "se vende heladera"}

    # Nueva oferta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    assert_receive {:oferta_aceptada, "john snow", "se vende heladera", 15}
    assert_receive {:oferta, "arya stark", "se vende heladera", 15, "john snow"}

    # Esperamos a que termine la subasta
    :timer.sleep(1000)

    # Notificacion a los clientes de la subasta finalizada
    assert_receive {:subasta_finished, "john snow", "se vende heladera"}
    assert_receive {:subasta_finished, "arya stark", "se vende heladera"}

    # Assert de quién ganó la subasta
    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 15
    assert subasta.duration == 1
    assert subasta.offerer == "john snow"
  end
end
