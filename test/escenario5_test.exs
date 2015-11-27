defmodule Escenario5Test do
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

# Mientras una subasta está en progreso, un vendedor (que puede ser el mismo de la anterior u otro)
# crea una nueva subasta, y las dos subastas estarán en progreso en simultáneo,
# funcionando cada una de ellas como siempre.

  test "Escenario 5", %{plataforma: plataforma} do
    # Se registran dos compradores
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

    # Otra subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, "vendo auto", 100, 3)
    assert_receive {:new_subasta, "arya stark", "vendo auto"}
    assert_receive {:new_subasta, "john snow", "vendo auto"}

    # Nueva oferta para la nueva subasta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "vendo auto", 150, "john snow")
    assert_receive {:oferta_aceptada, "john snow", "vendo auto", 150}
    assert_receive {:oferta, "arya stark", "vendo auto", 150, "john snow"}

    # Nueva oferta superior para la primer subasta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 200, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    # Esperamos a que termine la primer subasta
    :timer.sleep(1000)

    # Notificacion a los clientes de la subasta finalizada
    assert_receive {:subasta_finished, "john snow", "se vende heladera"}
    assert_receive {:subasta_finished, "arya stark", "se vende heladera"}

    # Corroboramos quién ganó la subasta
    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 200
    assert subasta.duration == 1
    assert subasta.offerer == "arya stark"

    # Esperamos a que termine la segunda subasta
    :timer.sleep(2000)

    # Notificacion a los clientes de la subasta finalizada
    assert_receive {:subasta_finished, "john snow", "vendo auto"}
    assert_receive {:subasta_finished, "arya stark", "vendo auto"}

    # Corroboramos quién ganó la subasta
    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "vendo auto")
    assert subasta.name == "vendo auto"
    assert subasta.price == 150
    assert subasta.duration == 3
    assert subasta.offerer == "john snow"
  end
end
