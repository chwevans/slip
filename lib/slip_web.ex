defmodule Slip.Web do
  require Lager

  @doc """
  Starts the web server
  """
  def start_link() do
    {:ok, port} = :application.get_env(:slip, :web_port)

    dispatch = :cowboy_router.compile([
                {:_, [{:_, Slip.Web, []}]}
               ])

    {:ok, _} = :cowboy.start_http(:http, 200,
                                  [port: port],
                                  [env: [dispatch: dispatch]])
  end

  def authenticate, do: {:unknown, 1}
  def authorize(user_auth_level, action_auth_level), do: user_auth_level >= action_auth_level

  def init(req, opts) do
    path = :cowboy_req.path(req)
    method = :cowboy_req.method(req)
    clean_method = String.to_atom(method)
    qs = :cowboy_req.parse_qs(req)

    # This will not stream request bodies, a strategy for large bodies has to be defined
    {:ok, body_qs, _} = :cowboy_req.body_qs(req)

    clean_qs = Enum.map(body_qs ++ qs, fn({k, v}) -> {String.to_atom(k), v} end)

    new_req = api_handler(req, clean_method, path, clean_qs)

    {:ok, new_req, opts}
  end

  def api_handler(req, method, path, parameters) do
    Lager.info('~p: ~p:~p', [method, path, parameters])
    try do
      Process.put(:parameters, parameters)

      {:ok, {module, authentication_function}} = :application.get_env(:slip, :authentication_function)
      {user, user_auth_level} = apply(module, authentication_function, [])

      Process.put(:user, user)
      Process.put(:user_authorization, user_auth_level)

      {:ok, result} = case path do
        "/favicon.ico" -> throw({:error, :notfound})
        path ->
          res = Slip.Action.execute(user_auth_level, method, Slip.Utils.to_route(path))
          JSX.encode(res)
      end
      ok(req, result)
    catch
      {:error, :forbidden} -> respond(req, 403, "403 Forbidden")
      {:error, :notfound} -> respond(req, 404, "404 Not found")
      {:error, {:notfound, what}} -> respond(req, 404, "404 Not found: #{what}")
      {:error, {:missing_parameter, p}} -> respond(req, 400, "Missing parameter: #{p}")
      {:error, {:invalid_parameter, p, options}} -> respond(req, 400, List.to_string(:io_lib.format("Invalid parameter: #{p}, options: ~p", [options])))
    end
  end

  def include_no_cache_header(header) do
    no_cache_header = [
      {"cache-control", "private, no-store, no-cache, must-revalidate, pre-check=0, post-check=0, max-age=0"},
      {"last-modified", :httpd_util.rfc1123_date},
      {"pragma", "no-cache"},
      {"expires", "Mon, 26 Jul 1997 05:00:00 GMT"},
    ]
    no_cache_header ++ header
  end

  def base_header(content_type) do
    [{"content-type", content_type}, {"Access-Control-Allow-Origin", "*"}]
  end

  def respond(req, error_code, message) do
    header = include_no_cache_header(base_header("text/plain; charset=utf-8"))
    :cowboy_req.reply(error_code, header, message, req)
  end

  def ok(req, message) do
    header = include_no_cache_header(base_header("application/json"))
    :cowboy_req.reply(200, header, message, req)
  end
end
