defmodule Plataforma.Supervisor do
  use Supervisor

  def start_link do
    IO.puts "Supervisor started"
    Supervisor.start_link(__MODULE__, :ok)
  end

  @name_ets ETS
  @name_plataforma Plataforma
  @name_controller Controller
  @name_notification Notification
  @name_event_handler :event_manager
  @name_comunicator Comunicator

  def init(:ok) do
    :ets.new(@name_ets,
                 [:set, :public, :named_table, {:read_concurrency, true}])
    children = [
      worker(GenEvent, [[name: @name_event_handler]]),
      worker(Plataforma, [@name_ets,  @name_event_handler, [name: @name_plataforma]]),
      worker(:elli, [[port: Application.get_env(:subastas, :port), callback: @name_controller]])
    ]

    supervise(children, strategy: :one_for_one)
  end

  def on_start(_) do
    GenEvent.add_handler(@name_notification, Notification, self())
    GenEvent.add_handler(@name_comunicator, Comunicator, %{plataforma: @name_plataforma, connected: false})
  end
end
