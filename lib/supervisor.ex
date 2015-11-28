defmodule Plataforma.Supervisor do
  use Supervisor

  def start_link do
    IO.puts "Supervisor started"
    Supervisor.start_link(__MODULE__, :ok)
  end

  @dets_alias DETS
  @name_dets_file 'subastas_db.dets'
  @name_plataforma Plataforma
  @name_controller Controller
  @name_event_handler Event_Manager

  def init(:ok) do
    :dets.open_file(@dets_alias, [file: @name_dets_file, type: :set])

    {:ok, pid} = GenEvent.start_link([name: @name_event_handler])
    GenEvent.add_mon_handler(@name_event_handler, Comunicator, @name_plataforma)

    children = [
      worker(Plataforma, [@dets_alias, @name_event_handler, Application.get_env(:subastas, :mode), [name: @name_plataforma]]),
      worker(:elli, [[port: Application.get_env(:subastas, :port), callback: @name_controller]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
