defmodule Plataforma do
  use GenServer

  ## Client API

  def start_link(dets, event_manager, opts \\ []) do
    GenServer.start_link(__MODULE__, {dets, event_manager}, opts)
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
    GenServer.cast(server, {:ofertar, {name, price, offerer}})
  end

  def close_subasta(server, subasta) do
    GenServer.cast(server, {:cerrar, subasta})
  end

  def cancelar_subasta(server, name) do
    GenServer.cast(server, {:cancel, name})
  end

  ## Server Callbacks

  def init({dets, event_manager}) do
    GenEvent.add_mon_handler(event_manager, Notification, self())
    {:ok, %{event_manager: event_manager, dets: dets, mode: Application.get_env(:subastas, :mode)}}
  end

  def handle_cast({:create_comprador, {name, value}}, state) do
    if state.mode == :primary do
      key = {name, :comprador}
      case lookup_dets(state.dets, key) do
        {:ok, entity} ->
          {:noreply, state}
        :not_found ->
          :dets.insert(state.dets, {key, value})
          GenEvent.notify(state.event_manager, {:send, {:create_comprador, {name, value}}})
          {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  def handle_cast({:create_subasta, {name, value}}, state) do
    key = {name, :subasta}
    case lookup_dets(state.dets, key) do
      {:ok, entity} ->
        {:noreply, state}
      :not_found ->
        :dets.insert(state.dets, {key, value})

        {:ok, pid} = GenEvent.start_link
        GenEvent.add_mon_handler(pid, SubastaFinisher, self())
        if state.mode == :primary do
          GenEvent.notify(pid, {:new_subasta, value})
          notify_subastas(state, name, value)
        else
          GenEvent.notify(pid, {:new_subasta,  %{value | duration: duration + 5}})
        end
        {:noreply, state}
    end
  end

  def handle_cast({:cerrar, subasta}, state) do
    key = {subasta.name, :subasta}
    case lookup_dets(state.dets, key) do
      {:ok, entity} ->
        # cerramo la subasta
        notify_subasta_finished(state.dets, state.event_manager, subasta.name)
        {:noreply, state}
      :not_found ->
        {:noreply, state}
    end
  end

  def handle_cast({:cancel, name}, state) do
    key = {name, :subasta}
    case lookup_dets(state.dets, key) do
      {:ok, entity} ->
        :dets.delete(state.dets, key)
        notify_cancel(state.dets, state.event_manager, name)
        {:noreply, state}
      :not_found ->
        {:noreply, state}
    end
  end

  def handle_cast({:ofertar, {name, price, offerer}}, state) do
      case lookup_dets(state.dets, {name, :subasta}) do
        {:ok, subasta} ->
          if price <= subasta.price do
            GenEvent.notify(state.event_manager, {:offer_too_low, offerer})
            {:noreply, state}
          else
            update_price(state.dets, name, price, offerer)
            notify_ofertas(state, name, price, offerer)
            {:noreply, state}
          end
        :not_found ->
          {:noreply, state}
    end
  end

  def handle_cast({:mode, new_mode}, state) do
    IO.puts "Se cambio el modo a #{new_mode}"
    {:noreply, %{state | mode: new_mode}}
  end

  def handle_cast({:message, message}, state) do
    GenServer.cast(self, message)
    {:noreply, state}
  end

  def handle_cast(_, state) do
    IO.puts "handle_cast ignored because it didnt match with anything"
    {:noreply, state}
  end

  def handle_call({:lookup, key}, _from, state) do
    case lookup_dets(state.dets, key) do
      {:ok, entity} ->
        {:reply, {:ok, entity}, state}
      :not_found ->
        {:reply, :not_found, state}
    end
  end

  # helper functions

  def lookup_dets(dets, key) do
    case :dets.lookup(dets, key) do
      [{key, entity}] -> {:ok, entity}
      [] -> :not_found
    end
  end

  def update_price(dets, name, new_price, offerer) do
    key = {name, :subasta}
    {:ok, subasta} = lookup_dets(dets, key)
    :dets.delete(dets, key)
    :dets.insert(dets, {key, %{subasta | price: new_price, offerer: offerer}})
  end

  def notify_subastas(state, subasta, value) do
    if state.mode == :primary do
      compradores = :dets.match(state.dets, {{:"$1",:comprador}, :"$2"})
      Enum.map(compradores,
        fn(result) ->
          case result do
            [_,comprador] ->
              GenEvent.notify(state.event_manager, {:new_subasta, comprador.name, subasta})
              :ok
          end
        end
      )
      GenEvent.notify(state.event_manager, {:send, {:create_subasta, {subasta, value}}})
    end
  end

  def notify_subasta_finished(dets, pid, subasta) do
    compradores = :dets.match(dets, {{:"$1",:comprador}, :"$2"})
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

  def notify_ofertas(state, subasta, price, offerer) do
    if state.mode == :primary do
      compradores = :dets.match(state.dets, {{:"$1",:comprador}, :"$2"})
      Enum.map(compradores,
        fn(result) ->
          case result do
            [_,comprador] ->
              if comprador.name == offerer do
                GenEvent.notify(state.event_manager, {:oferta_aceptada, comprador.name, subasta, price})
              else
                GenEvent.notify(state.event_manager, {:oferta, comprador.name, subasta, price, offerer})
              end
              :ok
          end
        end
      )
      GenEvent.notify(state.event_manager, {:send, {:ofertar, subasta, price, offerer}})
    end
  end

  def notify_cancel(dets, pid, subasta) do
    compradores = :dets.match(dets, {{:"$1",:comprador}, :"$2"})
    Enum.map(compradores,
      fn(result) ->
        case result do
          [_,comprador] ->
            GenEvent.notify(pid, {:cancel_subasta, comprador.name, subasta})
            :ok
        end
      end
    )
  end
end
