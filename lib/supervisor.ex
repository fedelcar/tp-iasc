defmodule Subastas.Supervisor do
  use Supervisor

  def start_link do
    IO.puts "Supervisor started"
    Supervisor.start_link(__MODULE__, :ok)
  end

  @name_subasta Subasta
  @name_controller Controller

  def init(:ok) do
    ets  = :ets.new(:table, [:named_table, read_concurrency: true])
    children = [
      worker(Subasta, [ets, [name: @name_subasta]]),
      worker(:elli, [[port: 3000, callback: Controller]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end