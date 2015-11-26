defmodule Notificacion do
  use GenEvent


  ## Server Callbacks

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, {}, opts)
  end

  def handle_event({:new_subasta, receptor, subasta}, state) do
    IO.puts "message to #{receptor}: Se ha creado la subasta #{subasta}"
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
end