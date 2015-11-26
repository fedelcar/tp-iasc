defmodule Subasta do
  use GenServer

  ## Client API

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, {key, values}) do
    GenServer.cast(server, {:create, {key, values}})
  end

  ## Server Callbacks

  def start_link(ets, opts \\ []) do
    GenServer.start_link(__MODULE__, ets, opts)
  end

  def handle_cast({:create, {key, values}}, ets) do
    case lookup_ets(ets, key) do
      {:ok, entity} ->
        {:noreply, ets}
      :not_found ->
        :ets.insert(ets, {key, values})
        {:noreply, ets}
    end
  end

  def handle_call({:lookup, key}, _from, ets) do
    case lookup_ets(ets, key) do
      {:ok, entity} ->
        {:reply, {:ok, entity}, ets}
      :not_found ->
        {:reply, :not_found, ets}
    end
  end

  def lookup_ets(ets, key) do
    case :ets.lookup(ets, key) do
      [entity] -> {:ok, entity}
      [] -> :not_found
    end
  end
end
