defmodule Controller do
  @behaviour :elli_handler

  def handle(elli_req, _args) do
    handle(:elli_request.method(elli_req), :elli_request.path(elli_req), elli_req)
  end

  #Subastas endpoint

  def handle(:GET, [<<"subastas">>, name], _req) do
    case Plataforma.lookup_subasta(Plataforma, name) do
      {:ok, subasta} ->
        {:ok, [{"Content-type", "application/json"}],
          "{\"name\":\"#{subasta.name}\", \"price\":\"#{subasta.price}\",
          \"duration\":\"#{subasta.duration}\", \"offerer\":\"#{subasta.offerer}\"}"}
      _ ->
        {404, [], "not found"}
    end
  end

  def handle(:POST, [<<"subastas">>], req) do
    case JSON.decode(:elli_request.body(req)) do
      {:ok, %{"name" => name, "base_price" => base_price, "duration" => duration}} ->
        if(is_number(base_price) && is_number(duration)) do
          Plataforma.create_subasta(Plataforma, name, base_price, duration)
          {:ok, [{"Content-type", "application/json"}], "{\"status\":\"created\"}"}
        else
          {400, [], "Bad Request"}
        end
      _ ->
        {400, [], "Bad Request"}
    end
  end

  def handle(:POST, [<<"subastas">>, <<"cancelar">>], req) do
    case JSON.decode(:elli_request.body(req)) do
      {:ok, %{"name" => name}} ->
        Plataforma.cancelar_subasta(Plataforma, name)
        {:ok, [{"Content-type", "application/json"}], "{\"status\":\"cancelled\"}"}
      _ ->
      {400, [], "Bad Request"}
    end
  end

  def handle(:POST, [<<"subastas">>, <<"ofertar">>], req) do
    case JSON.decode(:elli_request.body(req)) do
      {:ok, %{"subasta" => subasta_name, "comprador" => comprador_name, "precio" => precio}} ->
        if (is_number(precio)) do
          Plataforma.ofertar(Plataforma, subasta_name, precio, comprador_name)
          {:ok, [{"Content-type", "application/json"}], "{\"status\":\"ok\"}"}
        else
          {400, [], "Bad Request"}
        end
      _ ->
        {400, [], "Bad Request"}
    end
  end

  #Compradores endpoint

  def handle(:POST, [<<"compradores">>], req) do
    case JSON.decode(:elli_request.body(req)) do
      {:ok, %{"name" => name, "contacto" => contacto}} ->
        Plataforma.create_comprador(Plataforma, name, contacto)
        {:ok, [{"Content-type", "application/json"}], "{\"status\":\"created\"}"}
      _ ->
        {400, [], "Bad Request"}
    end
  end

  def handle(:GET, [<<"compradores">>, name], _req) do
    case Plataforma.lookup_comprador(Plataforma, name) do
      {:ok, comprador} ->
        {:ok, [{"Content-type", "application/json"}], "{\"name\":\"#{comprador.name}\", \"contacto\":\"#{comprador.contacto}\"}"}
      _ ->
        {404, [], "not found"}
    end
  end

  def handle(:POST, [<<"crash">>], _req) do
    raise "adios mundo cruel!"
  end

  def handle(_, _, _req) do
    {400, [], "Bad Request"}
  end

  def handle_event(:elli_startup, _, _config) do
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
end
