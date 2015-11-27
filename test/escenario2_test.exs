defmodule Escenario2Test do
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
    {:ok, dets} = :dets.open_file(@dets_alias, [file: @dets_file_name, type: :bag])

    {:ok, plataforma} = Plataforma.start_link(dets, notification, [])
    GenEvent.add_mon_handler(notification, Forwarder, self())

    on_exit fn ->
      :dets.close(dets)
      :file.delete(@dets_file_name)
    end

    {:ok, plataforma: plataforma}
  end


# Similar al escenario anterior, pero antes de terminar la subasta, B oferta un precio mayor,
# y al cumplirse el plazo, se le adjudica a éste.
# Obviamente, este proceso de superar la oferta anterior puede repetirse indefinidamente mientras la subasta esté abierta.

  test "Escenario 2", %{plataforma: plataforma} do

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

    # Esperamos a que termine la subasta
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
  end
end
