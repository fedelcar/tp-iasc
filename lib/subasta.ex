defmodule Subasta do
  use GenServer

  def start_link(ets, opts \\ []) do
    GenServer.start_link(__MODULE__, ets, opts)
  end

  def handle_call(:get, _from, nombre) do
    {:reply, h, ets}
  end

  def handle_cast({:create, name}, ets) do
    :ets.lookup(ets, name)
      {:ok, subasta} ->
        {:noreply, ets}
      :error ->
        :ets.insert(ets, {name})
        {:noreply, ets}
    end
  end

  def lookup(table, name) do
    case :ets.lookup(table, name) do
      [{^name, bucket}] -> {:ok, bucket}
      [] -> :error
    end
  end
end