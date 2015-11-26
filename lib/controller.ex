defmodule Controller do
  @behaviour :elli_handler

  def handle(elli_req, _args) do
    req = Elli.HTTPRequest.new elli_req
    handle(req.method, req.path, req)
  end

  def handle(:GET, [<<"subastas">>], req) do
    name = req.get_arg("name")
    {:ok, subasta} = Plataforma.lookup_subasta(Plataforma, name)
    {:ok, [{"Content-type", "application/json"}],
       "{\"name\":\"#{subasta.name}\", \"price\":\"#{subasta.price}\",
        \"duration\":\"#{subasta.duration}\", \"offerer\":\"#{subasta.offerer}\"}"}
  end

  def handle(:GET, [<<"compradores">>], req) do
    name = req.get_arg("name")
    {:ok, comprador} = Plataforma.lookup_comprador(Plataforma, name)
    {:ok, [{"Content-type", "application/json"}], "{\"name\":\"#{comprador.name}\", \"contacto\":\"#{comprador.contacto}\"}"}
  end

  def handle(:POST, [<<"subastas">>], req) do
    map = parse_body(req)
    name = Map.get(map, "name")
    base_price_str = Map.get(map, "base_price")
    duration_str = Map.get(map, "duration")

    case {name, base_price_str, duration_str} do
      {nil, _, _} -> {400, [], "Bad Request"}
      {_, nil, _} -> {400, [], "Bad Request"}
      {_, _, nil} -> {400, [], "Bad Request"}
      {name, base_price_str, duration_str} ->
        {duration, _} = Integer.parse(duration_str)
        {base_price, _} = Integer.parse(base_price_str)
        Plataforma.create_subasta(Plataforma, name, base_price, duration)
        {:ok, [{"Content-type", "application/json"}], "{\"status\":\"created\"}"}
    end
  end

  def handle(:POST, [<<"compradores">>], req) do
    map = parse_body(req)
    name = Map.get(map, "name")
    contacto = Map.get(map, "contacto")

    case {name, contacto} do
      {nil, _} -> {400, [], "Bad Request"}
      {_, nil} -> {400, [], "Bad Request"}
      {name, contacto} ->
        Plataforma.create_comprador(Plataforma, name, contacto)
        {:ok, [{"Content-type", "application/json"}], "{\"status\":\"created\"}"}
    end
  end

  def handle(:POST, [<<"crash">>], _req) do
    raise "adios mundo cruel!"
  end

  def handle(_, _, _req) do
    {400, [], "Bad Request"}
  end

  def handle_event(:elli_startup, [_req, _exit, _stack], _config) do
    :ok
  end

  def handle_event(:request_complete, [_req, _responseCode, _responseHeaders,
                                _responseBody, _timings], _config) do
    :ok
  end

  def handle_event(:request_throw, [req, exception, stack], _config) do
    log_exception(req, exception, stack)
  end

  def handle_event(:request_exit, [_req, _exit, _stack], _config) do
    :ok
  end

  def handle_event(:request_closed, _data, _config) do
    :ok
  end

  def handle_event(:request_error, [req, error, stack], _config) do
    log_exception(req, error, stack)
    :ok
  end

  def handle_event(:request_parse_error, [data], _args) do
    :error_logger.error_msg("request parse error: ~p", [data])
    :ok
  end

  def handle_event(:bad_request, data, _args) do
    :error_logger.error_msg("bad request: ~p", [data])
    :ok
  end

  def handle_event(:client_closed, [_when], _config) do
    :ok
  end

  def handle_event(event, data, args) do
    :error_logger.error_msg("unhandled event: ~p, ~p, ~p", [event, data, args])
    :ok
  end

  def log_exception(req, exception, stack) do
    :error_logger.error_msg("exception: ~p~nstack: ~p~nrequest: ~p~n",
                           [exception, stack, :elli_request.to_proplist(req)])
    :ok
  end

  # parsed body

  def parse_body(req) do
    list = Enum.filter(String.split(req.body, "&"), fn(x) -> x != "" end)
    List.foldl(list, %{}, fn (x, m) -> add_to_map(x, m) end)
  end

  def add_to_map(x, map) do
    list = String.split(x, "=")
    Map.put(map, List.first(list), List.last(list))
  end
end
