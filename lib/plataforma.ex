defmodule Plataforma do
  use GenServer

  ## Client API

  def start_link(ets, notification, opts \\ []) do
    GenServer.start_link(__MODULE__, {ets, notification}, opts)
  end

  def lookup_subasta(server, name) do
    key = {name, :subasta}
    GenServer.call(server, {:lookup, key})
  end

  def create_subasta(server, name, base_price, duration) do
    GenServer.cast(server,
      {:create, {{name, :subasta}, %Subasta{name: name, price: base_price, duration: duration, offerer: :no_offered_yet}}})
  end

  def lookup_comprador(server, name) do
    key = {name, :comprador}
    GenServer.call(server, {:lookup, key})
  end

  def create_comprador(server, name, contacto) do
    GenServer.cast(server, 
      {:create, {{name, :comprador}, %Comprador{name: name, contacto: contacto}}})
  end

  def ofertar(server, name, price, offerer) do
    GenServer.call(server, {:ofertar, {name, price, offerer}})
  end

  ## Server Callbacks

  def init({ets, notification}) do
    {:ok, %{notification: notification, ets: ets}}
  end

  def handle_cast({:create, {key, value}}, state) do
    case lookup_ets(state.ets, key) do
      {:ok, entity} ->
        {:noreply, state}
      :not_found ->
        case key do
          {name, :comprador} ->
            :ets.insert(state.ets, {key, value})
            {:noreply, state}
          {name, :subasta} ->
            :ets.insert(state.ets, {key, value})
            compradores = :ets.match(state.ets, {:"_", :"$1"})
            Enum.map(compradores, 
              fn(result) -> 
                case result do
                  [comprador] ->
                    GenEvent.notify(state.notification, {:new_subasta, name, comprador.name})
                    :ok
                  _ -> 
                    :ok
                end
              end
            )
            {:noreply, state}
        end
    end
  end

  def handle_call({:lookup, key}, _from, state) do
    case lookup_ets(state.ets, key) do
      {:ok, entity} ->
        {:reply, {:ok, entity}, state}
      :not_found ->
        {:reply, :not_found, state}
    end
  end

  def handle_call({:ofertar, {name, price, offerer}}, _from, state) do
      case lookup_ets(state.ets, {name, :subasta}) do
        {:ok, subasta} ->
          if price <= subasta.price do
            {:reply, {:bad_request, "La oferta no es lo suficientemente alta"}, state}
          else
            update_price(state.ets, name, price, offerer)
            {:reply, {:ok, "Oferta aceptada"}, state}
          end
        :not_found ->
          {:reply, :not_found, state}
    end
  end

  def lookup_ets(ets, key) do
    case :ets.lookup(ets, key) do
      [{key, entity}] -> {:ok, entity}
      [] -> :not_found
    end
  end

  def update_price(ets, name, new_price, offerer) do
    key = {name, :subasta}
    {:ok, subasta} = lookup_ets(ets, key)
    :ets.delete(ets, key)
    :ets.insert(ets, {key, %{subasta | price: new_price, offerer: offerer}})
  end

end
