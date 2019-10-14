defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{
    JSONParser,
    Context,
    TLEParser,
    Function,
    UserFunction,
    TemplateParameters
  }

  alias __MODULE__.{
    Numeric,
    Comparison,
    Logical,
    ArraysAndObjects,
    Strings,
    Deployment,
    Resource
  }

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions
  @pure_functions %{
    "copyIndex" => &Numeric.copyIndex/2,
    "add" => &Numeric.add/1,
    "sub" => &Numeric.sub/1,
    "mul" => &Numeric.mul/1,
    "div" => &Numeric.div/1,
    "mod" => &Numeric.mod/1,
    "int" => &Numeric.int/1,
    "float" => &Numeric.float/1,
    "max" => &Numeric.max/1,
    "min" => &Numeric.min/1,
    "equals" => &Comparison.comparison_equals/1,
    "greater" => &Comparison.comparison_greater/1,
    "greaterOrEquals" => &Comparison.comparison_greaterOrEquals/1,
    "less" => &Comparison.comparison_less/1,
    "lessOrEquals" => &Comparison.comparison_lessOrEquals/1,
    "and" => &Logical.and_/1,
    "bool" => &Logical.bool_/1,
    "or" => &Logical.or_/1,
    "not" => &Logical.not_/1,
    "if" => &Logical.if_/1,
    "length" => &ArraysAndObjects.length/1,
    "first" => &ArraysAndObjects.first/1,
    "last" => &ArraysAndObjects.last/1,
    "array" => &ArraysAndObjects.array/1,
    "createArray" => &ArraysAndObjects.createArray/1,
    "empty" => &ArraysAndObjects.empty/1,
    "json" => &ArraysAndObjects.json/1,
    "range" => &ArraysAndObjects.range/1,
    "concat" => &ArraysAndObjects.concat/1,
    "contains" => &ArraysAndObjects.contains/1,
    "intersection" => &ArraysAndObjects.intersection/1,
    "union" => &ArraysAndObjects.union/1,
    "coalesce" => &ArraysAndObjects.coalesce/1,
    "base64" => &Strings.base64/1,
    "base64ToJson" => &Strings.base64ToJson/1,
    "base64ToString" => &Strings.base64ToString/1,
    "dataUri" => &Strings.dataUri/1,
    "dataUriToString" => &Strings.dataUriToString/1,
    "endsWith" => &Strings.endsWith/1,
    "startsWith" => &Strings.startsWith/1,
    "format" => &Strings.format/1,
    "guid" => &Strings.guid/1,
    "newGuid" => &Strings.newGuid/1,
    "uniqueString" => &Strings.uniqueString/1,
    "uri" => &Strings.uri/1,
    "uriComponent" => &Strings.uriComponent/1,
    "uriComponentToString" => &Strings.uriComponentToString/1,
    "padLeft" => &Strings.padLeft/1,
    "indexOf" => &Strings.indexOf/1,
    "lastIndexOf" => &Strings.lastIndexOf/1,
    "replace" => &Strings.replace/1,
    "split" => &Strings.split/1,
    "string" => &Strings.string/1,
    "substring" => &Strings.substring/1,
    "take" => &Strings.take/1,
    "skip" => &Strings.skip/1,
    "toLower" => &Strings.toLower/1,
    "toUpper" => &Strings.toUpper/1,
    "trim" => &Strings.trim/1,
    "utcNow" => &Strings.utcNow/1,
    "variables" => &Deployment.variables/2,
    "parameters" => &Deployment.parameters/2,
    "subscription" => &Resource.subscription/2,
    "resourceGroup" => &Resource.resourceGroup/2,
    "resourceId" => &Resource.resourceId/2,
    "reference" => &Resource.reference/2
  }

  @evaluatable_arm_sections ["variables", "resources", "outputs"]

  def evaluate_arm_document(context = %Context{}) do
    context =
      context
      |> TemplateParameters.evaluate_effective_parameters()
      |> UserFunction.register_user_functions()

    @evaluatable_arm_sections
    |> Enum.reduce(context, &evaluate_document_region/2)
  end

  defp evaluate_document_region(name, context = %Context{})
       when name in @evaluatable_arm_sections do
    json = context |> Map.fetch!(:json)
    doc_content = json |> Kernel.get_in([:value, :value])
    index = doc_content |> Enum.find_index(&(&1 |> Map.get(:key) == name))

    case index do
      nil ->
        # region doesn't exist in document, so return unmodified context
        context

      _ ->
        updated_region =
          doc_content
          |> Enum.at(index)
          |> __MODULE__.evaluate_node(context)

        doc_content = doc_content |> List.replace_at(index, updated_region)
        updated_json = json |> Kernel.put_in([:value, :value], doc_content)
        context |> Map.put(:json, updated_json)
    end
  end

  def evaluate_node(v, context = %Context{}) do
    case v do
      v when is_map(v) -> v |> Map.update!(:value, fn x -> evaluate_node(x, context) end)
      v when is_list(v) -> v |> Enum.map(fn x -> evaluate_node(x, context) end)
      v when is_binary(v) -> v |> arm_apply(context)
      v -> v
    end
  end

  defp find_function_implementation(f = %Function{}, context = %Context{}) do
    full_name = f |> Function.full_name()

    cond do
      # Ensure we first search in context, then in global functions. Otherwise, calls to parameters() in a user function end up in the global implementation
      nil != get_in(context, [:functions, full_name]) ->
        {:ok, get_in(context, [:functions, full_name])}

      nil != get_in(@pure_functions, [full_name]) ->
        {:ok, get_in(@pure_functions, [full_name])}

      true ->
        {:error, "Function #{full_name}() not found."}
    end
  end

  defp apply_function(arguments, f = %Function{}, context = %Context{}, func_impl) do
    case func_impl |> :erlang.fun_info() |> Keyword.get(:arity) do
      1 ->
        arguments |> func_impl.()

      2 ->
        arguments |> func_impl.(context)

      other_arity ->
        {:error,
         "Function #{f |> Function.full_name()}() has arity /#{other_arity}, which is not supported."}
    end

    # |> IO.inspect(label: :apply_function)
  end

  def arm_apply(f = %Function{args: args, property_path: property_path}, context = %Context{}) do
    with {:ok, func_impl} = find_function_implementation(f, context) do
      args
      |> Enum.map(fn arg -> arg |> arm_apply(context) end)
      |> apply_function(f, context, func_impl)
      |> evaluate_property_path(property_path)
    end
  end

  def arm_apply(value, context = %Context{}) when value |> is_binary() do
    case value |> TLEParser.parse() do
      x = %Function{} -> arm_apply(x, context)
      x -> x
    end
  end

  def arm_apply(value, %Context{}), do: value

  defp evaluate_property_path(e = {:error, _}, _), do: e

  defp evaluate_property_path(value, property_path),
    do: List.foldl(property_path, value, &JSONParser.fetch/2)
end
