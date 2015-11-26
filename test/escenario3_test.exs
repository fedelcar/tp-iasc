defmodule Escenario3Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, [])
    {:ok, plataforma: plataforma}
  end

# Similar a los escenarios anteriores, pero el vendedor cancela la subasta antes de la expiración
# de la subasta y adjudicación del ganador. En este caso, obviamente, nadie gana la subasta,
# y todos los compradores son notificados.

  test "escenario3", %{plataforma: plataforma} do
    Plataforma.create_comprador(plataforma, "john snow", "idontknownothing@gmail.com")
    Plataforma.create_comprador(plataforma, "arya stark", "deathismyfried@gmail.com")

    Plataforma.create_subasta(plataforma, "se vende heladera", 10, 1)
    # Notificacion a los clientes de la nueva subasta

    Plataforma.ofertar(plataforma, "se vende heladera", 15, "john snow")
    # Notificacion a los clientes de la oferta

    :timer.sleep(1000)
    

    # Implementar cancelacion

  end
end
