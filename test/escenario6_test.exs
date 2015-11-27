defmodule Escenario6Test do
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

    # Nueva subasta y notifiación a todos de la misma
    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    assert_receive {:new_subasta, "arya stark", "se vende heladera"}
    assert_receive {:new_subasta, "john snow", "se vende heladera"}

    # Nueva oferta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    assert_receive {:oferta_aceptada, "john snow", "se vende heladera", 15}
    assert_receive {:oferta, "arya stark", "se vende heladera", 15, "john snow"}

    # Nueva oferta superior para la primer subasta y notificación a todos de la misma
    Plataforma.ofertar(plataforma, "se vende heladera", 200, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    # Se 'cae' la plataforma por un huracán....
    Process.kill(plataforma, :killed_by_hurricane)

    # Esperamos a que se levanta la plataforma alternativa
    :timer.sleep(2000)

    # La plataforma nueva puede recibir ofertas
    Plataforma.ofertar(plataforma, "se vende heladera", 300, "arya stark")
    assert_receive {:oferta_aceptada, "arya stark", "se vende heladera", 200}
    assert_receive {:oferta, "john snow", "se vende heladera", 200, "arya stark"}

    # Esperamos a que termine la subasta, tomando en cuenta los 5 segundos extra
    :timer.sleep(6000)

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
