defmodule SubastasTest do
  use ExUnit.Case

  setup do
    ets = :ets.new(:registry_table, [:set, :public])
    {:ok, subasta} = Subasta.start_link(ets, [])
    {:ok, subasta: subasta, ets: ets}
  end

  test "spawns subastas", %{subasta: subasta, ets: ets} do
    assert Subasta.lookup(subasta, "vendo_auto") == :not_found

    Subasta.create(subasta, {"vendo_auto", 10, 20})
    assert {:ok, {"vendo_auto", 10, 20}} = Subasta.lookup(subasta, "vendo_auto")

    # KV.Bucket.put(bucket, "milk", 1)
    # assert KV.Bucket.get(bucket, "milk") == 1
  end
end
