defmodule Main do
  use Application

  def start(_type, _args) do
    IO.puts "App started"
    Subastas.Supervisor.start_link
  end
end