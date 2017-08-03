defmodule Slip do
  use Application

  def start(_type, _args) do
    Slip.Supervisor.start_link
  end

  def get_user, do: Process.get(:user)
  def get_user_authorization, do: Process.get(:user_authorization)
  def get_parameters(req_params), do: Slip.Utils.get_parameters(req_params)

  defmacro get(path, action_auth_level, contents) do
    route = Slip.Utils.to_route(path)
    make_route(:GET, route, action_auth_level, contents)
  end

  defmacro post(path, action_auth_level, contents) do
    route = Slip.Utils.to_route(path)
    make_route(:POST, route, action_auth_level, contents)
  end

  defp make_route(method, route, action_auth_level, contents) do
    quote do
      def route(unquote(method), unquote(route), user_auth_level) do
        {:ok, {module, authorization_function}} = :application.get_env(:slip, :authorization_function)
        case apply(module, authorization_function, [user_auth_level, unquote(action_auth_level)]) do
          false -> throw({:error, :forbidden})
          true ->
            [{:'do', resp}] = unquote(contents)
            resp
        end
      end
    end
  end
end
