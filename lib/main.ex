defmodule Main do
  use Application

  def start(_type, _args) do
    IO.puts "App started"
    Plataforma.Supervisor.start_link
  end
end