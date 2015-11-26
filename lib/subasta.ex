defmodule Subasta do
  use GenServer

  ## Client API

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, {name, price, lifespan}) do
    GenServer.cast(server, {:create, {name, price, lifespan}})
  end

  ## Server Callbacks

  def start_link(ets, opts \\ []) do
    GenServer.start_link(__MODULE__, ets, opts)
  end

  def handle_cast({:create, {name, price, lifespan}}, ets) do
    case lookup_ets(ets, name) do
      {:ok, subasta} ->
        {:noreply, ets}
      :not_found ->
        :ets.insert(ets, {name, price, lifespan})
        {:noreply, ets}
    end
  end

  def handle_call({:lookup, name}, _from, ets) do
    case lookup_ets(ets, name) do
      {:ok, subasta} ->
        {:reply, {:ok, subasta}, ets}
      :not_found ->
        {:reply, :not_found, ets}
    end
  end

  def lookup_ets(ets, name) do
    case :ets.lookup(ets, name) do
      [subasta] -> {:ok, subasta}
      [] -> :not_found
    end
  end
end
