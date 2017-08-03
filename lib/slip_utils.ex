defmodule Slip.Utils do
  def to_route(path) do
    String.split(String.strip(path, ?/), "/")
  end

  ## Utilities to get parameters out of the request
  def get_parameters(req_params) do
    parameters = Process.get(:parameters, [])
    Enum.reduce(req_params, %{}, fn(requirement = {name, _}, map) ->
      result = get_parameter(requirement, parameters)
      Map.put(map, name, result)
    end)
  end

  defp get_parameter({name, {:atom, possible_atoms, default}}, parameters) do
      case parameters[name] do
        nil -> default
        value ->
          atom_value = try do
            case value do
              value when is_list(value) -> List.to_existing_atom(value)
              value when is_binary(value) -> String.to_existing_atom(value)
              value -> value
            end
          rescue
            ArgumentError -> throw({:error, {:invalid_parameter, name, possible_atoms}})
          end
          case Enum.member?(possible_atoms, atom_value) do
            true -> atom_value
            false -> throw({:error, {:invalid_parameter, name, possible_atoms}})
          end
      end
  end
  defp get_parameter({name, {:atom, possible_atoms}}, parameters) do
    case get_parameter({name, {:atom, possible_atoms, "undefined"}}, parameters) do
      "undefined" -> throw({:error, {:invalid_parameter, name, possible_atoms}})
      v -> v
    end
  end

  defp get_parameter({name, {type, default}}, parameters) do
    value = case parameters[name] do
      nil -> default
      v -> v
    end
    convert(value, type)
  end

  defp get_parameter({name, type}, parameters) do
    case get_parameter({name, {type, :undefined}}, parameters) do
      :undefined -> throw({:error, {:missing_parameter, name}})
      v -> v
    end
  end

  # Integers
  defp convert(value, :integer) when is_list(value), do: List.to_integer(value)
  defp convert(value, :integer) when is_binary(value), do: String.to_integer(value)
  defp convert(value, :integer), do: value

  # Float
  defp convert(value, :float) when is_list(value), do: List.to_float(value)
  defp convert(value, :float) when is_binary(value), do: String.to_float(value)
  defp convert(value, :float), do: value

  # Binary
  defp convert(value, :binary) when is_list(value), do: List.to_string(value)
  defp convert(value, :binary) when is_number(value), do: Integer.to_string(value)
  defp convert(value, :binary), do: value

end
