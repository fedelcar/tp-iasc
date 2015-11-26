defmodule Subasta do
  use GenServer

  ## Client API

  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  def create(server, {key, values}) do
    GenServer.cast(server, {:create, {key, values}})
  end

  def ofertar(server, name, price, offerer) do
    GenServer.call(server, {:ofertar, {name, price, offerer}})
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
        case key do
          {_, :subasta} ->
            IO.puts "todos putos"
            IO.puts length :ets.match(ets, '_')
          _ ->
        end

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

  def handle_call({:ofertar, {name, price, offerer}}, _from, ets) do
      case lookup_ets(ets, {name, :subasta}) do
      {:ok, {{name, _}, {winning_price, _, _}}} ->
        if price <= winning_price do
          {:reply, {:bad_request, "Oferta mas baja a la ganador gato"}, ets}
        else
          ## puts price in the subasta
          update_price(ets, name, price, offerer)
          IO.puts 'tamo'
          {:reply, {:ok, "Todo piola"}, ets}
        end
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

  def update_price(ets, name, price, offerer) do
    key = {name, :subasta}
    {:ok, {_, {_, duration, _}}} = lookup_ets(ets, key)
    :ets.delete(ets, key)
    :ets.insert(ets, {key, {price, duration, offerer}})
  end
end
