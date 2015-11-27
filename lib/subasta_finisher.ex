defmodule SubastaFinisher do
  use GenEvent

  def handle_event({:new_subasta, subasta}, parent) do
    timeout = subasta.duration
    :timer.sleep(timeout * 1000)
    Plataforma.close_subasta(parent, subasta)
    {:ok, parent}
  end

end
