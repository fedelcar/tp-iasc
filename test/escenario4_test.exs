defmodule Escenario4Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:ets_name, [:set, :public])
    {:ok, plataforma} = Plataforma.start_link(ets, [])
    {:ok, plataforma: plataforma}
  end

# Similar a los escenarios anteriores, pero un tercer participante, C, se registra después de que la
# subasta inició y antes de que termine. C podrá hacer ofertas y ganar la subasta como cualquier
# otro participante (A y B, en este caso)

  test "escenario4", %{plataforma: plataforma} do
  end
end
