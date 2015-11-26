defmodule Subasta do
  use GenServer

  ## Client API

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end


  ## Server Callbacks

  def start_link(ets, opts \\ []) do
    GenServer.start_link(__MODULE__, ets, opts)
  end

  def handle_cast({:create, name}, ets) do
    case lookup(ets, name) do
      {:ok, subasta} ->
        {:noreply, ets}
      :not_found ->
        :ets.insert(ets, {name})
        {:noreply, ets}
    end
  end

  def handle_call({:lookup, name}, _from, ets) do
    case lookup(ets, name) do
      {:ok, subasta} ->
        {:reply, {:ok, subasta}, ets}
      :not_found ->
        {:reply, :not_found, ets}
    end
  end

  def lookup(ets, name) do
    case :ets.lookup(ets, name) do
      [{^name, subasta}] -> {:ok, subasta}
      [] -> :not_found
    end
  end
end