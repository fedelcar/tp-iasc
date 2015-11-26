defmodule Escenario6Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, [])
    {:ok, plataforma: plataforma}
  end

# Con la subasta ya en progreso, el servidor abruptamente falla por un error de hardware. En no más
# de 5 segundos un segundo servidor debe levantarse y continuar con la subasta.
# Esto significa que de alguna forma los clientes tienen que dejar de hablar con el servidor caído,
# para empezar a hablar con el nuevo servidor.

# Vamos a considerar en el error kernel (es decir, los datos que no podemos perder) a:
# la existencia de la subasta
# si empezó
# y si terminó, con qué precio y a quien se le adjudicó
# la mayor oferta aceptada hasta ahora dentro de la subasta

# Cuando se produce una caída, se debería extender el plazo de la subasta en 5 segundos.

  test "escenario6", %{plataforma: plataforma} do
  end
end
