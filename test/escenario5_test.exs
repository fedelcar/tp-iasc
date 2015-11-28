defmodule Escenario5Test do
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

# Mientras una subasta está en progreso, un vendedor (que puede ser el mismo de la anterior u otro)
# crea una nueva subasta, y las dos subastas estarán en progreso en simultáneo,
# funcionando cada una de ellas como siempre.

  test "Escenario 5", %{plataforma: plataforma} do

    subasta1 = %Subasta{name: "se vende heladera", price: 10, duration: 1} 
    subasta2 = %Subasta{name: "vendo auto", price: 100, duration: 3} 

    # Se registran dos compradores
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")

    # Nueva subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    assert_receive {:new_subasta, "arya stark", subasta1}
    assert_receive {:new_subasta, "john snow", subasta1}

    # Nueva oferta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    assert_receive {:oferta_aceptada, "john snow", "se vende heladera", 15}
    assert_receive {:oferta, "arya stark", "se vende heladera", 15, "john snow"}

    # Otra subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, "vendo auto", 100, 3)
    assert_receive {:new_subasta, "arya stark", subasta2}
    assert_receive {:new_subasta, "john snow", subasta2}

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
    subasta_offered1 = %Subasta{subasta1 | offerer: "arya stark", price: 200}
    assert_receive {:subasta_finished, "john snow", subasta_offered1}
    assert_receive {:subasta_finished, "arya stark", subasta_offered}

    # Esperamos a que termine la segunda subasta
    :timer.sleep(2000)

    # Notificacion a los clientes de la subasta finalizada
    subasta_offere2 = %Subasta{subasta2 | offerer: "john snow", price: 150}
    assert_receive {:subasta_finished, "john snow", subasta_offere2}
    assert_receive {:subasta_finished, "arya stark",subasta_offere2}
    assert_receive {:send, {:cerrar, "se vende heladera"}} ## Comunicator received for forward
  end
end
