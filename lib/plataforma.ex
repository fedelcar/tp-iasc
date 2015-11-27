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
      {:create_subasta, {name, %Subasta{name: name, price: base_price, duration: duration, offerer: :no_offered_yet}}})
  end

  def lookup_comprador(server, name) do
    key = {name, :comprador}
    GenServer.call(server, {:lookup, key})
  end

  def create_comprador(server, name, contacto) do
    GenServer.cast(server,
      {:create_comprador, {name, %Comprador{name: name, contacto: contacto}}})
  end

  def ofertar(server, name, price, offerer) do
    GenServer.call(server, {:ofertar, {name, price, offerer}})
  end

  def close_subasta(server, subasta) do
    GenServer.cast(server, {:cerrar, subasta})
  end

  ## Server Callbacks

  def init({ets, notification}) do
    {:ok, %{notification: notification, ets: ets}}
  end

  def handle_cast({:create_comprador, {name, value}}, state) do
    key = {name, :comprador}
    case lookup_ets(state.ets, key) do
      {:ok, entity} ->
        {:noreply, state}
      :not_found ->
        :ets.insert(state.ets, {key, value})
        {:noreply, state}
    end
  end

  def handle_cast({:create_subasta, {name, value}}, state) do
    key = {name, :subasta}
    case lookup_ets(state.ets, key) do
      {:ok, entity} ->
        {:noreply, state}
      :not_found ->
        subasta = {key, value}
        :ets.insert(state.ets, subasta)

        {:ok, pid} = GenEvent.start_link
        GenEvent.add_mon_handler(pid, SubastaFinisher, self())
        GenEvent.notify(pid, {:new_subasta, subasta})
        notify_subastas(state.ets, state.notification, name)
        {:noreply, state}
    end
  end

  def handle_cast({:cerrar, subasta}, state) do
    key = {subasta.name, :subasta}
    case lookup_ets(state.ets, key) do
      {:ok, entity} ->
        # cerramo la subasta
        notify_subasta_finished(state.ets, state.notification, subasta.name)
        {:noreply, state}
      :not_found ->
        {:noreply, state}
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
            notify_ofertas(state.ets, state.notification, name, price, offerer)
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

  # notification functions

  def notify_subastas(ets, pid, subasta) do
    compradores = :ets.match(ets, {{:"$1",:comprador}, :"$2"})
    Enum.map(compradores,
      fn(result) ->
        case result do
          [_,comprador] ->
            GenEvent.notify(pid, {:new_subasta, comprador.name, subasta})
            :ok
        end
      end
    )
  end

  def notify_subasta_finished(ets, pid, subasta) do
    compradores = :ets.match(ets, {{:"$1",:comprador}, :"$2"})
    Enum.map(compradores,
      fn(result) ->
        case result do
          [_,comprador] ->
            GenEvent.notify(pid, {:subasta_finished, comprador.name, subasta})
            :ok
        end
      end
    )
  end

  def notify_ofertas(ets, pid, subasta, price, offerer) do
    compradores = :ets.match(ets, {{:"$1",:comprador}, :"$2"})
    Enum.map(compradores,
      fn(result) ->
        case result do
          [_,comprador] ->
            if comprador.name == offerer do
              GenEvent.notify(pid, {:oferta_aceptada, comprador.name, subasta, price})
            else
              GenEvent.notify(pid, {:oferta, comprador.name, subasta, price, offerer})
            end
            :ok
        end
      end
    )
  end
end
