defmodule Comunicator do
  use GenEvent

  def init(name_plataforma) do
    IO.puts "Comunicator started"
    {:ok, %{plataforma: name_plataforma, connected: false}}
  end 

  def handle_event({:message, message}, state) do
    IO.puts "me llego un mensaje al comunicator #{message}"
    GenServer.cast(state.plataforma, message)
    {:ok, state}
  end

  def handle_event({:send, mensaje}, state) do
    if !state.connected do
      case Node.connect(get_node) do
        true ->
          IO.puts "conexion exitosa con el node #{get_node}"
          Node.monitor(get_node, true)
          GenServer.cast({__MODULE__, get_node}, {:message, mensaje})
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
      GenServer.cast(state.plataforma, {:mode, :secondaty})
    end
    {:ok, %{state | :connected => false}}
  end

  def get_node do
    Application.get_env(:subastas, :node)
  end
end