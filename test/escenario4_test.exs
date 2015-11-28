defmodule Escenario4Test do
  use ExUnit.Case

  defmodule Forwarder do
    use GenEvent

    def handle_event(event, parent) do
      send parent, event
      {:ok, parent}
    end
  end

  @dets_file_name 'test_db.dets'
  @dets_alias :dets_alias

  setup do
    {:ok, notification} = GenEvent.start_link
    {:ok, dets} = :dets.open_file(@dets_alias, [file: @dets_file_name, type: :set])

    {:ok, plataforma} = Plataforma.start_link(dets, notification, :primary, [])
    GenEvent.add_mon_handler(notification, Forwarder, self())

    on_exit fn ->
      :dets.close(dets)
      :file.delete(@dets_file_name)
    end

    {:ok, plataforma: plataforma}
  end

# Similar a los escenarios anteriores, pero un tercer participante, C, se registra después de que la
# subasta inició y antes de que termine. C podrá hacer ofertas y ganar la subasta como cualquier
# otro participante (A y B, en este caso)

  test "Escenario 4", %{plataforma: plataforma} do
    subasta = %Subasta{name: "se vende heladera", price: 10, duration: 1}

    # Se registran los dos compradores
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")

    # Nueva subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, subasta.name, subasta.price, subasta.duration)
    assert_receive {:new_subasta, "arya stark", subasta}
    assert_receive {:new_subasta, "john snow", subasta}

    # Nueva oferta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    assert_receive {:oferta_aceptada, "john snow", "se vende heladera", 15}
    assert_receive {:oferta, "arya stark", "se vende heladera", 15, "john snow"}

     # Nueva oferta, pero es inferior a la ganadora, por lo que se ignora
    Plataforma.ofertar(plataforma, subasta.name, 10, "arya stark")
    assert_receive {:offer_too_low, "arya stark", 10, "se vende heladera"}

    # Nueva oferta superior y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 200, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    :timer.sleep(300)

    # Luego de empezada la subasta, un nuevo comprador hace ofertas
    Plataforma.create_comprador(plataforma, "ron damon", "ron_damon@gmail.com")
    Plataforma.ofertar(plataforma, subasta.name, 300, "ron damon")
    assert_receive {:oferta_aceptada, "ron damon", "se vende heladera", 300}
    assert_receive {:oferta, "arya stark", "se vende heladera", 300, "ron damon"}
    assert_receive {:oferta, "john snow", "se vende heladera", 300, "ron damon"}

    # Esperamos a que termine la subasta
    :timer.sleep(800)

    # Notificacion a los clientes de la subasta finalizada
    subasta_offered = %Subasta{subasta | offerer: "john snow"}
    assert_receive {:subasta_finished, "john snow",  subasta_offered}
    assert_receive {:subasta_finished, "arya stark", subasta_offered}
    assert_receive {:subasta_finished, "ron damon", subasta_offered}
  end
end
