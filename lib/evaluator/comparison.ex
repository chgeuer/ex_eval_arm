defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator.Comparison do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.

  #
  # equals
  #
  def comparison_equals([operand1, operand2]), do: operand1 === operand2

  #
  # less
  #
  def comparison_less([operand1, operand2]) when is_integer(operand1) and is_integer(operand2),
    do: operand1 < operand2

  def comparison_less([operand1, operand2]) when is_binary(operand1) and is_binary(operand2),
    do: {:error, :not_implemented_unclear_specification}

  def comparison_less(_), do: {:error, :unsupported_args}

  #
  # lessOrEquals
  #
  def comparison_lessOrEquals([operand1, operand2])
      when is_integer(operand1) and is_integer(operand2),
      do: operand1 <= operand2

  def comparison_lessOrEquals([operand1, operand2])
      when is_binary(operand1) and is_binary(operand2),
      do: {:error, :not_implemented_unclear_specification}

  def comparison_lessOrEquals(_), do: {:error, :unsupported_args}

  #
  # greater
  #
  def comparison_greater([operand1, operand2])
      when is_integer(operand1) and is_integer(operand2),
      do: operand1 > operand2

  def comparison_greater([operand1, operand2]) when is_binary(operand1) and is_binary(operand2),
    do: {:error, :not_implemented_unclear_specification}

  def comparison_greater(_), do: {:error, :unsupported_args}

  #
  # greaterOrEquals
  #
  def comparison_greaterOrEquals([operand1, operand2])
      when is_integer(operand1) and is_integer(operand2),
      do: operand1 >= operand2

  def comparison_greaterOrEquals([operand1, operand2])
      when is_binary(operand1) and is_binary(operand2),
      do: {:error, :not_implemented_unclear_specification}

  def comparison_greaterOrEquals(_), do: {:error, :unsupported_args}
end
