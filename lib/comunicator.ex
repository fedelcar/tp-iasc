defmodule Comunicator do
  use GenServer

  ## Client API

  def start_link(opts \\ []) do
    [node] = Application.get_env(:subastas, :node)
    case Node.connect(node) do
      true ->
        IO.puts "conexion exitosa con el node #{node}"
      false ->
        IO.puts "conexion fallida con el node #{node}"
      :ignored ->  
        IO.puts "conexion ignorada"
    end
    GenServer.start_link(__MODULE__, opts)
  end

  ## Server Callbacks

  def handle_cast({:message, mensaje}, state) do
    IO.puts "me llego un mensaje al comunicator #{mensaje}"
    {:noreply, state}
  end
end