defmodule Notificacion do
  use GenEvent

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

  def handle_event({:cancel_subasta, receptor, subasta}, state) do
    IO.puts "message to #{receptor}: Subasta #{subasta} cancelada"
    {:ok, state}
  end

  def handle_event({:subasta_finished, receptor, subasta}, state) do
    IO.puts "message to #{receptor}: Subasta #{subasta} ha finalizado"
    {:ok, state}
  end
end
