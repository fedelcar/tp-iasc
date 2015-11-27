defmodule Escenario3Test do
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

# Similar a los escenarios anteriores, pero el vendedor cancela la subasta antes de la expiración
# de la subasta y adjudicación del ganador. En este caso, obviamente, nadie gana la subasta,
# y todos los compradores son notificados.

  test "Escenario 3", %{plataforma: plataforma} do

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

    # Antes de que expire la subasta, la misma se cancela y se notifica a todos
    :timer.sleep(300)
    Plataforma.cancelar_subasta(plataforma, "se vende heladera")
    assert_receive {:send, {:cancel, "se vende heladera"}} ## Comunicator received for forward
    assert_receive{:cancel_subasta, "arya stark", "se vende heladera"}
    assert_receive{:cancel_subasta, "john snow", "se vende heladera"}

    # Verificamos que la subasta ya no está activa en la plataforma
    assert :not_found = Plataforma.lookup_subasta(plataforma, "se vende heladera")
  end
end
