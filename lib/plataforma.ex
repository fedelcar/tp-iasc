defmodule Plataforma do
  use GenServer

  ## Client API

  def lookup_subasta(server, name) do
    case GenServer.call(server, {:lookup, {name, :subasta}}) do
      :not_found -> 
        :not_found
      {:ok, {{name, :subasta}, {subasta}}} -> 
        {:ok, subasta}
    end
  end

  def create_subasta(server, name, base_price, duration) do
    GenServer.cast(server,
      {:create, {{name, :subasta}, {%Subasta{name: name, price: base_price, duration: duration, offerer: :no_offered_yet}}}})
  end

  def lookup_comprador(server, name) do
    case GenServer.call(server, {:lookup, {name, :comprador}}) do
      :not_found -> 
        :not_found
      {:ok, {{name, :comprador}, {comprador}}} -> 
        {:ok, comprador}
    end
  end

  def create_comprador(server, name, contacto) do
    GenServer.cast(server, 
      {:create, {{name, :comprador}, {%Comprador{name: name, contacto: contacto}}}})
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
        {:ok, {_, {subasta}}} ->
          if price <= subasta.price do
            {:reply, {:bad_request, "La oferta no es lo suficientemente alta"}, ets}
          else
            update_price(ets, name, price, offerer)
            {:reply, {:ok, "Oferta aceptada"}, ets}
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

  def update_price(ets, name, new_price, offerer) do
    key = {name, :subasta}
    {:ok, {_, {subasta}}} = lookup_ets(ets, key)
    :ets.delete(ets, key)
    :ets.insert(ets, {key, {%{subasta | price: new_price, offerer: offerer}}})
  end
end
