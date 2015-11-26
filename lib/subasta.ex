defmodule Subasta do
  use GenServer

  def start_link(state, opts \\ []) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def handle_cast({:create, name}, state) do
    case :ets.lookup(state, name) do
      [{^name, subasta}] -> {:noreply, state}
      [] -> {:noreply, state}
    end 
  end

end