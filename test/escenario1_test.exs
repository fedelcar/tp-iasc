defmodule Escenario1Test do
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
    {:ok, event_manager} = GenEvent.start_link
    {:ok, dets} = :dets.open_file(@dets_alias, [file: @dets_file_name, type: :set])

    {:ok, plataforma} = Plataforma.start_link(dets, event_manager, :primary, [])
    GenEvent.add_mon_handler(event_manager, Forwarder, self())

    on_exit fn ->
      :dets.close(dets)
      :file.delete(@dets_file_name)
    end

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

    # Esperamos a que termine la subasta
    :timer.sleep(1000)

    # Notificacion a los clientes de la subasta finalizada
    subasta_offered = %Subasta{subasta | offerer: "john snow", price: 15}
    assert_receive {:subasta_finished, "john snow",  subasta_offered}
    assert_receive {:subasta_finished, "arya stark", subasta_offered}
  end
end
