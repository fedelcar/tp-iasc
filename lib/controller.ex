defmodule Controller do
  @behaviour :elli_handler

  def handle(elli_req, args) do
    req = Elli.HTTPRequest.new elli_req
    handle(req.method, req.path, req)
  end

  def handle(:GET, [<<"subastas">>], req) do
    {:ok, [{"Content-type", "application/json"}], "{\"status\":\"aca va la lista de las subastas\"}"}
  end

  def handle(:POST, [<<"subastas">>], req) do
    {:ok, [{"Content-type", "application/json"}], "{\"status\":\"ok post\"}"}
  end

  def handle(:POST, [<<"crash">>], _req) do
    raise "adios mundo cruel!"
  end

  def handle(_, _, _req) do
    {400, [], "Bad Request"}
  end

  # @doc: Handle request events, like request completed, exception
  # thrown, client timeout, etc. Must return 'ok'.
  def handle_event(_event, _data, _args) do
    :ok
  end
end
