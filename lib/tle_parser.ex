defmodule Microsoft.Azure.TemplateLanguageExpressions.TLEParser do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.Function
  import NimbleParsec

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/template-expressions

  t_true = choice([string("true"), string("TRUE")]) |> replace(true)
  t_false = choice([string("false"), string("FALSE")]) |> replace(false)
  t_boolean = choice([t_true, t_false])

  # t_number = integer(min: 1) |> unwrap_and_tag(:arm_number)
  defp to_integer(acc), do: acc |> Enum.join() |> String.to_integer(10)

  t_number =
    optional(string("-"))
    |> ascii_string([?0..?9], min: 1)
    |> reduce(:to_integer)

  defp not_quote(<<?', ?', _::binary>>, context, _, _), do: {:cont, context}
  defp not_quote(<<?', _::binary>>, context, _, _), do: {:halt, context}
  defp not_quote(_, context, _, _), do: {:cont, context}

  t_string =
    ignore(string(~S/'/))
    |> repeat_while(
      choice([
        replace(string(~S/\"/), ~S/"/),
        replace(string(~S/''/), ~S/'/),
        utf8_char([])
      ]),
      {:not_quote, []}
    )
    |> ignore(string(~S/'/))
    |> reduce({List, :to_string, []})

  defp to_function_name(_rest, acc, context, _line, _offset) do
    name = acc |> Enum.reverse() |> List.to_string()

    case name |> String.split(".") do
      [namespace, name] -> {[name: name, namespace: namespace], context}
      [name] -> {[name: name, namespace: nil], context}
    end
  end

  t_whitespace = ascii_char([?\s, ?\t]) |> times(min: 1)

  t_function_args =
    ignore(string("("))
    |> optional(parsec(:expression))
    |> repeat(
      ignore(ascii_char([?,]))
      |> concat(parsec(:expression))
    )
    |> ignore(string(")"))
    |> tag(:args)

  t_property_access =
    repeat(
      choice([
        ignore(string("."))
        |> ascii_string([?a..?z, ?A..?Z, ?0..?9, ?_], min: 1)
        |> unwrap_and_tag(:property),
        ignore(string("["))
        |> choice([
          integer(min: 1),
          # XXX
          ignore(optional(t_whitespace))
          |> ignore(string(~S/'/))
          |> repeat_while(
            choice([
              replace(string(~S/\"/), ~S/"/),
              replace(string(~S/''/), ~S/'/),
              utf8_char([])
            ]),
            {:not_quote, []}
          )
          |> ignore(string(~S/'/))
          |> ignore(optional(t_whitespace))
          |> reduce({List, :to_string, []})
        ])
        |> unwrap_and_tag(:indexer)
        |> ignore(string("]"))
      ])
    )
    |> tag(:property_path)

  t_function =
    ascii_char([?a..?z])
    |> repeat(ascii_char([?a..?z, ?A..?Z, ?0..?9, ?_, ?.]))
    |> post_traverse(:to_function_name)
    |> tag(:name)
    |> post_traverse({:bubble_up_name_and_namespace, [:name]})
    |> concat(t_function_args)
    |> concat(t_property_access)
    |> post_traverse({:to_function_struct, []})

  defp to_function_struct(_rest, acc, context, _line, _offset),
    do: {struct(Function, acc |> Enum.into(%{})) |> List.wrap(), context}

  defp bubble_up_name_and_namespace(_rest, acc, context, _line, _offset, elem)
       when is_atom(elem) do
    data = acc |> Keyword.fetch!(elem)

    {acc
     |> Keyword.delete(elem)
     |> Keyword.merge(data), context}
  end

  t_expression =
    ignore(optional(t_whitespace))
    |> choice([
      t_string,
      t_boolean,
      t_number,
      t_function
    ])
    |> ignore(optional(t_whitespace))

  t_arm =
    choice([
      lookahead(string(~S/[[/))
      |> utf8_string([], min: 0),
      ignore(utf8_char([?[])) |> concat(t_expression) |> ignore(utf8_char([?]])),
      utf8_string([], min: 0)
    ])

  defparsecp(:expression, t_expression)

  defparsec(:arm, t_arm)

  def parse(s), do: s |> arm() |> elem(1) |> hd()
end
