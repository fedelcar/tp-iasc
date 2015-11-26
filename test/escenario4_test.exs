defmodule Escenario4Test do
  use ExUnit.Case

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    {:ok, subasta} = Subasta.start_link(ets, [])
    {:ok, subasta: subasta}
  end

# Similar a los escenarios anteriores, pero un tercer participante, C, se registra después de que la
# subasta inició y antes de que termine. C podrá hacer ofertas y ganar la subasta como cualquier
# otro participante (A y B, en este caso)

  test "escenario4", %{subasta: subasta} do
  end
end
