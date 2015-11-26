defmodule Escenario5Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, [])
    {:ok, plataforma: plataforma}
  end

# Mientras una subasta está en progreso, un vendedor (que puede ser el mismo de la anterior u otro)
# crea una nueva subasta, y las dos subastas estarán en progreso en simultáneo,
# funcionando cada una de ellas como siempre.

  test "escenario5", %{plataforma: plataforma} do
  end
end
