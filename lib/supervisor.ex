defmodule Subastas.Supervisor do
  use Supervisor

  def start_link do
    IO.puts "Supervisor started"
    Supervisor.start_link(__MODULE__, :ok)
  end

  @name_ets Subasta
  @name_subasta Subasta

  def init(:ok) do
  ets = :ets.new(@name_ets,
                 [:set, :public, :named_table, {:read_concurrency, true}])
    children = [
      worker(Subasta, [ets, [name: @name_subasta]]),
      worker(:elli, [[port: 3000, callback: Controller]])
    ]

    supervise(children, strategy: :one_for_one)
  end
end