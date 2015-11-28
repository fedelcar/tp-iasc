defmodule Escenario6Test do
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

# Con la subasta ya en progreso, el servidor abruptamente falla por un error de hardware. En no más
# de 5 segundos un segundo servidor debe levantarse y continuar con la subasta.
#
# Esto significa que de alguna forma los clientes tienen que dejar de hablar con el servidor caído,
# para empezar a hablar con el nuevo servidor.
#
# Vamos a considerar en el error kernel (es decir, los datos que no podemos perder) a:
#   la existencia de la subasta
#   si empezó
#   y si terminó, con qué precio y a quien se le adjudicó
#   la mayor oferta aceptada hasta ahora dentro de la subasta
#
# Cuando se produce una caída, se debería extender el plazo de la subasta en 5 segundos.

  test "Escenario 6", %{plataforma: plataforma} do
    # Se registran dos compradores
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")


    subasta = %Subasta{name: "se vende heladera", price: 10, duration: 1}
    # Nueva subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, subasta.name, subasta.price, subasta.duration)
    assert_receive {:send, {:create_subasta, {"se vende heladera", _}}} ## Comunicator received for forward
    assert_receive {:new_subasta, "arya stark", subasta}
    assert_receive {:new_subasta, "john snow", subasta}

    # Nueva oferta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    assert_receive {:send, {:ofertar, "se vende heladera", 15, "john snow"}} ## Comunicator received for forward
    assert_receive {:oferta_aceptada, "john snow", "se vende heladera", 15}
    assert_receive {:oferta, "arya stark", "se vende heladera", 15, "john snow"}

    # Nueva oferta superior para la primer subasta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 200, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    # Se 'cae' la plataforma por un huracán....
    Process.exit(plataforma, :normal)

    # Esperamos a que se levanta la plataforma alternativa
    :timer.sleep(2000)

    # La plataforma nueva puede recibir ofertas
    Plataforma.ofertar(plataforma, "se vende heladera", 300, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 300}
    assert_receive {:oferta, "john snow", "se vende heladera", 300, "arya stark"}

    # Esperamos a que termine la subasta
    :timer.sleep(1000)

    subasta_to_finish = %Subasta{subasta | offerer: "arya stark", price: 200}
    # Notificacion a los clientes de la subasta finalizada
    assert_receive {:subasta_finished, "john snow", subasta_to_finish}
    assert_receive {:subasta_finished, "arya stark", subasta_to_finish}

    # Corroboramos quién ganó la subasta
    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 300
    assert subasta.duration == 1
    assert subasta.offerer == "arya stark"

  end
end
