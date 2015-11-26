defmodule Notificacion do
  use GenEvent


  ## Server Callbacks

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, {}, opts)
  end

  def handle_event({:new_subasta, comprador, subasta}, state) do
    IO.puts "message to #{comprador}: Se ha creado la subasta #{subasta}"
    {:ok, state}
  end
end