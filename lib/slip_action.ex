defmodule Slip.Action do
  require Lager

  def execute(user_auth_level, method, path) do
    {:ok, action_modules} = :application.get_env(:slip, :action_modules)
    try_module(action_modules, user_auth_level, method, path)
  end

  defp try_module([], _, _, _), do: throw({:error, :notfound})
  defp try_module([mod | modules], user_auth_level, method, path) do
    try do
      mod.route(method, path, user_auth_level)
    catch
      :error, :function_clause -> try_module(modules, user_auth_level, method, path)
    end
  end
end
