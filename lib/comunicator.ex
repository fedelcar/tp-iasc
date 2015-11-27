defmodule Comunicator do
  use GenServer

  ## Client API

  def start_link(plataforma, opts \\ []) do
    GenServer.start_link(__MODULE__, {plataforma}, opts)
  end

  ## Server Callbacks

  def init({plataforma}) do
    {:ok, %{plataforma: plataforma, connected: false}}
  end

  def handle_cast({:message, message}, state) do
    IO.puts "me llego un mensaje al comunicator #{message}"
    GenServer.cast(state.plataforma, message)
    {:noreply, state}
  end

  def handle_cast({:send, mensaje}, state) do
    if !state.connected do
      case Node.connect(get_node) do
        true ->
          IO.puts "conexion exitosa con el node #{node}"
          Node.monitor(get_node, true)
          GenServer.cast({__MODULE__, get_node}, {:message, mensaje})
          {:noreply, %{state | connected: true}}
        false ->
          IO.puts "conexion fallida con el node #{node}"
          {:noreply, %{state | connected: false}} 
        :ignored ->  
          IO.puts "conexion ignorada"
          {:noreply, %{state | connected: false}}
      end
    else
      GenServer.cast({__MODULE__, get_node}, {:message, mensaje})
      {:noreply, state} 
    end
  end

  def handle_cast({nodedown, node}, state) do
    IO.puts "Se cayo el nodo!"
    GenServer.cast(state.plataforma, {:mode, :secondaty})
    {:noreply, %{state | connected: false}}
  end

  def get_node do
    Application.get_env(:subastas, :node)
  end
end