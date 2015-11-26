defmodule Escenarios_Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, [])
    {:ok, plataforma: plataforma}
  end

  test "escenario1", %{plataforma: plataforma} do
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")

    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    # Notificacion a los clientes de la nueva subasta

    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    # Notificacion a los clientes de la oferta

    :timer.sleep(1000)
    # Notificacion a los clientes de la subasta finalizada

    {:ok, subasta} = Plataforma.lookup_subasta(plataforma, "se vende heladera")
    assert subasta.name == "se vende heladera"
    assert subasta.price == 15
    assert subasta.duration == 1
    assert subasta.offerer == "john snow"
  end
end