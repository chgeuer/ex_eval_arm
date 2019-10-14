defmodule Microsoft.Azure.TemplateLanguageExpressions.UserFunction do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{Evaluator, Context, JSONParser}
  alias JSONParser.{JSONDocument}

  def register_user_functions(context = %Context{json: json}) do
    context
    |> Map.put(:functions, create_user_functions(json))
  end

  defp create_user_functions(json = %JSONDocument{}) do
    # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-authoring-templates#functions

    with {"functions", functions} <-
           json |> JSONParser.get(["functions"]) |> JSONParser.to_elixir() do
      functions
      |> Enum.map(fn %{"namespace" => namespace, "members" => members} -> {namespace, members} end)
      |> Enum.flat_map(fn {namespace, name_and_body} ->
        Enum.map(name_and_body, fn {name, body} ->
          {"#{namespace}.#{name}", create_user_function("#{namespace}.#{name}", body)}
        end)
      end)
      |> Enum.into(%{})
    end
  end

  defp create_user_function(name, %{
         "parameters" => parameters,
         "output" => %{"value" => output_expression}
       })
       when is_list(parameters) do
    #
    # Higher-order function which returns the actual function implementation
    #
    fn arguments ->
      case ensure_runtime_args_match_required_parameters(arguments, parameters) do
        {:error, error_message} ->
          "ERROR calling '#{name}()': #{error_message}"

        {:ok, computed_arguments} ->
          the_function = fn [name], _context ->
            computed_arguments |> Map.fetch!(name)
          end

          context =
            Context.new()
            |> Context.inject_functions(%{"parameters" => the_function})

          output_expression
          |> Evaluator.evaluate_node(context)
      end
    end
  end

  defp ensure_runtime_args_match_required_parameters(arguments, parameters) do
    {args, errors} =
      parameters
      |> merge_parameters(arguments)
      |> Enum.map(&validate_argument_type/1)
      |> Enum.reduce({%{}, []}, fn arg, _accumulator = {args, errors} ->
        case arg do
          {%{"name" => arg_name}, arg_value} -> {args |> Map.put(arg_name, arg_value), errors}
          arg when is_binary(arg) -> {args, [arg | errors]}
        end
      end)

    case {args, errors} do
      {_, errors} when errors != [] ->
        {:error,
         errors
         |> Enum.reverse()
         |> Enum.join("\n")}

      _ ->
        {:ok, args}
    end
  end

  defp merge_parameters([parameter_head | parameter_tail], [argument_head | argument_tail]),
    do: [{parameter_head, argument_head} | merge_parameters(parameter_tail, argument_tail)]

  defp merge_parameters([], []), do: []

  defp merge_parameters(
         [
           %{"name" => name_of_required_argument, "type" => type_of_required_argument}
           | more_required_args
         ],
         []
       ),
       do: [
         "Missing #{type_of_required_argument} argument '#{name_of_required_argument}'"
         | merge_parameters(more_required_args, [])
       ]

  defp merge_parameters([], [user_supplied_argument | even_more_args]),
    do: [
      "Unexpected argument '#{inspect(user_supplied_argument)}'"
      | merge_parameters([], even_more_args)
    ]

  # [
  #   {"string", quote do &is_binary/1 end},
  #   {"securestring", quote do &is_binary/1 end},
  #   {"int", quote do &is_integer/1 end},
  #   {"bool", quote do &is_boolean/1 end},
  #   {"object", quote do &is_map/1 end},
  #   {"secureobject", quote do &is_map/1 end},
  #   {"array", quote do &is_list/1 end} ] |> Enum.map(fn {type, guard} ->
  #     defp validate_argument_type(x = {%{"type" => unquote(type)}, value}) when (unquote(guard)).(value), do: x
  #     defp validate_argument_type({%{"name" => name, "type" => unquote(type)}, value}), do: "Argument #{name} requires a #{unquote(type)}, got #{inspect(value)}"
  # end)

  defp validate_argument_type(x = {%{"type" => "string"}, value}) when is_binary(value), do: x

  defp validate_argument_type({%{"name" => name, "type" => "string"}, value}),
    do: "Argument #{name} requires a string, got #{inspect(value)}"

  defp validate_argument_type(x = {%{"type" => "securestring"}, value}) when is_binary(value),
    do: x

  defp validate_argument_type({%{"name" => name, "type" => "securestring"}, value}),
    do: "Argument #{name} requires a securestring, got #{inspect(value)}"

  defp validate_argument_type(x = {%{"type" => "int"}, value}) when is_integer(value), do: x

  defp validate_argument_type({%{"name" => name, "type" => "int"}, value}),
    do: "Argument #{name} requires a int, got #{inspect(value)}"

  defp validate_argument_type(x = {%{"type" => "bool"}, value}) when is_boolean(value), do: x

  defp validate_argument_type({%{"name" => name, "type" => "bool"}, value}),
    do: "Argument #{name} requires a bool, got #{inspect(value)}"

  defp validate_argument_type(x = {%{"type" => "object"}, value}) when is_map(value), do: x

  defp validate_argument_type({%{"name" => name, "type" => "object"}, value}),
    do: "Argument #{name} requires a object, got #{inspect(value)}"

  defp validate_argument_type(x = {%{"type" => "secureobject"}, value}) when is_map(value), do: x

  defp validate_argument_type({%{"name" => name, "type" => "secureobject"}, value}),
    do: "Argument #{name} requires a secureobject, got #{inspect(value)}"

  defp validate_argument_type(x = {%{"type" => "array"}, value}) when is_list(value), do: x

  defp validate_argument_type({%{"name" => name, "type" => "array"}, value}),
    do: "Argument #{name} requires a array, got #{inspect(value)}"

  defp validate_argument_type({%{"type" => unknown_type, "name" => name}, _}),
    do: "Unknown argument type #{unknown_type} for argument #{name}"

  defp validate_argument_type(x), do: x
end
