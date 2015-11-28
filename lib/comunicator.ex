defmodule Comunicator do
  use GenEvent

  def init(name_plataforma) do
    IO.puts "Comunicator started"
    {:ok, %{plataforma: name_plataforma, connected: false}}
  end

  def handle_event({:send, mensaje}, state) do
    if !state.connected do
      case Node.connect(get_node) do
        true ->
          IO.puts "conexion exitosa con el node #{get_node}"
          Node.monitor(get_node, true)
          GenServer.cast({state.plataforma, get_node}, {:message, mensaje})
          {:ok, %{state | :connected => true}}
        false ->
          IO.puts "conexion fallida con el node #{get_node}"
          {:ok, %{state | :connected => false}}
        :ignored ->
          IO.puts "conexion ignorada"
          {:ok, %{state | :connected => false}}
      end
    else
      GenServer.cast({__MODULE__, get_node}, {:message, mensaje})
      {:ok, state}
    end
  end

  def handle_info({:nodedown, node}, state) do
    if get_node == node do
      GenServer.cast(state.plataforma, {:mode, :primary})
    end
    {:ok, %{state | :connected => false}}
  end

  def get_node do
    Application.get_env(:subastas, :node)
  end

  #Handlers

  def handle_event({:new_subasta, receptor, subasta}, state) do
    IO.puts "message to #{receptor}: Se ha creado la subasta #{subasta.name} que finaliza en #{subasta.duration} segundos"
    {:ok, state}
  end

  def handle_event({:oferta, receptor, subasta, price, offerer}, state) do
    IO.puts "message to #{receptor}: Se ha ofertado #{price} en la subasta #{subasta} por el comprador #{offerer}"
    {:ok, state}
  end

  def handle_event({:oferta_aceptada, receptor, subasta, price}, state) do
    IO.puts "message to #{receptor}: oferta aceptada para la subasta #{subasta} por la cantidad #{price}"
    {:ok, state}
  end

  def handle_event({:offer_too_low, receptor, price, subasta}, state) do
    IO.puts "message to #{receptor}: Tu oferta de #{price} para la subasta #{subasta} es muy baja"
    {:ok, state}
  end

  def handle_event({:cancel_subasta, receptor, subasta}, state) do
    IO.puts "message to #{receptor}: Subasta #{subasta} cancelada"
    {:ok, state}
  end

  def handle_event({:subasta_finished, receptor, subasta}, state) do
    IO.puts "message to #{receptor}: Subasta #{subasta.name} ha finalizado. Ganador: #{subasta.offerer}"
    {:ok, state}
  end

end
