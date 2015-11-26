defmodule Escenario2Test do
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

  

# Similar al escenario anterior, pero antes de terminar la subasta, B oferta un precio mayor,
# y al cumplirse el plazo, se le adjudica a éste.
# Obviamente, este proceso de superar la oferta anterior puede repetirse indefinidamente mientras la subasta esté abierta.

  test "escenario2", %{plataforma: plataforma} do
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")

    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    assert_receive {:new_subasta, "arya stark", "se vende heladera"}
    assert_receive {:new_subasta, "john snow", "se vende heladera"}

    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    assert_receive {:oferta_aceptada, "john snow", "se vende heladera", 15}
    assert_receive {:oferta, "arya stark", "se vende heladera", 15, "john snow"}

    Plataforma.ofertar(plataforma, "se vende heladera", 200, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    # Notificacion a los clientes de la oferta

    :timer.sleep(1000)
    # Notificacion a los clientes de la subasta finalizada

    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 200
    assert subasta.duration == 1
    assert subasta.offerer == "arya stark"
  end
end
