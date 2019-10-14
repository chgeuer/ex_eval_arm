defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator.Logical do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-logical

  #
  # and
  #
  def and_(vals), do: vals |> List.foldl(true, &Kernel.and/2)

  #
  # bool
  #
  def bool_([integer]) when is_integer(integer), do: integer != 0

  def bool_([s]) when is_binary(s) do
    case s |> String.downcase() do
      "false" -> false
      "true" -> true
      _ -> {:error, :unsupported_argument}
    end
  end

  def bool_(_), do: {:error, :unsupported_argument}

  #
  # if
  #
  def if_([condition, trueValue, falseValue]) when is_boolean(condition) do
    case condition do
      true -> trueValue
      false -> falseValue
    end
  end

  #
  # not
  #
  def not_([val]) when is_boolean(val), do: !val

  #
  # or
  #
  def or_(vals), do: vals |> List.foldl(false, &Kernel.or/2)
end
