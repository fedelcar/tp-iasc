defmodule Escenario4Test do
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


# Similar a los escenarios anteriores, pero un tercer participante, C, se registra después de que la
# subasta inició y antes de que termine. C podrá hacer ofertas y ganar la subasta como cualquier
# otro participante (A y B, en este caso)

  test "escenario4", %{plataforma: plataforma} do
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

     # Nueva oferta, pero es inferior a la ganadora, por lo que se ignora
    Plataforma.ofertar(plataforma, "se vende heladera", 10, "arya stark")
    assert_receive {:offer_too_low, "arya stark"}

    # Nueva oferta superior y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 200, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    :timer.sleep(300)

    # Luego de empezada la subasta, un nuevo comprador hace ofertas
    Plataforma.create_comprador(plataforma, "ron damon", "ron_damon@gmail.com")
    Plataforma.ofertar(plataforma, "se vende heladera", 300, "ron damon")
    assert_receive {:oferta_aceptada, "ron damon", "se vende heladera", 300}
    assert_receive {:oferta, "arya stark", "se vende heladera", 300, "ron damon"}
    assert_receive {:oferta, "john snow", "se vende heladera", 300, "ron damon"}

    # Esperamos a que termine la subasta
    :timer.sleep(800)

    # Notificacion a los clientes de la subasta finalizada
    assert_receive {:subasta_finished, "john snow", "se vende heladera"}
    assert_receive {:subasta_finished, "arya stark", "se vende heladera"}
    assert_receive {:subasta_finished, "ron damon", "se vende heladera"}

    # Corroboramos quién ganó la subasta
    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 300
    assert subasta.duration == 1
    assert subasta.offerer == "ron damon"
  end
end
