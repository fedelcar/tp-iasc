defmodule Plataforma.Supervisor do
  use Supervisor

  def start_link do
    IO.puts "Supervisor started"
    Supervisor.start_link(__MODULE__, :ok)
  end

  @name_ets ETS
  @name_plataforma Plataforma
  @name_controller Controller
  @name_notification Notificacion
  @name_comunicator Comunicator

  def init(:ok) do
    ets = :ets.new(@name_ets,
                 [:set, :public, :named_table, {:read_concurrency, true}])
    children = [
      worker(Comunicator, [[name: @name_comunicator]]),
      worker(Notificacion, [[name: @name_notification]]),
      worker(Plataforma, [@name_ets,  @name_notification, [name: @name_plataforma]]),
      worker(:elli, [[port: 3000, callback: @name_controller]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
