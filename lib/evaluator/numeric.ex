defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator.Numeric do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  #
  # add
  #
  def add(two_operands), do: two_operands |> op_int2(&Kernel.+/2)

  #
  # copyIndex
  #
  def copyIndex(_, _), do: 999

  #
  # div
  #
  def div(two_operands), do: two_operands |> op_int2(&div/2)

  #
  # float
  #
  def float([int]) when is_number(int), do: int / 1

  def float([string]) when is_binary(string) do
    case string |> Float.parse() do
      {i, ""} -> i
      _ -> "Cannot parse int('#{string}')"
    end
  end

  #
  # int
  #
  def int([string]) when is_binary(string) do
    case string |> Integer.parse() do
      {i, ""} -> i
      _ -> "Cannot parse int('#{string}')"
    end
  end

  # array of integers, or comma-separated list of integers
  defp inner_array([a]) when is_list(a), do: a
  defp inner_array(a) when is_list(a), do: a

  #
  # min
  #
  def min(a), do: a |> inner_array() |> Enum.min()

  #
  # max
  #
  def max(a), do: a |> inner_array() |> Enum.max()

  #
  # mod
  #
  def mod(two_operands), do: two_operands |> op_int2(&rem/2)

  #
  # mul
  #
  def mul(two_operands), do: two_operands |> op_int2(&Kernel.*/2)

  #
  # sub
  #
  def sub(two_operands), do: two_operands |> op_int2(&Kernel.-/2)

  defp op_int2([operand1, operand2], operation)
       when is_integer(operand1) and is_integer(operand2) and is_function(operation),
       do: operation.(operand1, operand2)
end
