ExUnit.start()

defmodule Microsoft.Azure.TemplateLanguageExpressions.TestHelper do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{JSONParser, Evaluator, Context}
  use ExUnit.Case

  defmacro json_roundtrip(expression) do
    quote do
      test "Roundtrip JSON expression \"#{unquote(expression) |> String.slice(0, 200)}\"" do
        assert unquote(expression) ===
                 unquote(expression) |> JSONParser.parse() |> JSONParser.encode()
      end
    end
  end

  defmacro json_roundtrip(expression, expected) do
    quote do
      test "Roundtrip JSON expression \"#{unquote(expression) |> String.slice(0, 200)}\"" do
        assert unquote(expression) ===
                 unquote(expression) |> JSONParser.parse() |> JSONParser.encode()
      end

      test "Parse JSON expression \"#{unquote(expression) |> String.slice(0, 200)}\"" do
        assert unquote(expected) ===
                 unquote(expression) |> JSONParser.parse() |> JSONParser.to_elixir()
      end
    end
  end

  defmacro evaluate_node(node_expression, expected) do
    quote do
      test "Evaluate JSON expression \"#{unquote(node_expression) |> String.slice(0, 200)}\"" do
        assert unquote(expected) ===
                 unquote(node_expression)
                 |> JSONParser.parse()
                 |> Evaluator.evaluate_node(Context.new())
                 |> JSONParser.to_elixir()
      end
    end
  end

  defmacro evaluate_doc(expression, expected) do
    quote do
      test "Evaluate JSON expression \"#{unquote(expression) |> String.slice(0, 200)}\"" do
        assert unquote(expected) ===
                 Context.new()
                 |> Context.with_json_string(unquote(expression))
                 |> Evaluator.evaluate_arm_document()
                 |> Map.fetch!(:json)
                 |> JSONParser.to_elixir()
      end
    end
  end

  # defmacro evaluate_node(node_expression, expected, context) do
  #   quote do
  #     test "Evaluate JSON document \"#{unquote(node_expression) |> String.slice(0, 200)}\"" do
  #       assert unquote(expected) ===
  #                unquote(node_expression)
  #                |> JSONParser.parse()
  #                |> Evaluator.evaluate_node(context)
  #                |> JSONParser.to_elixir()
  #     end
  #   end
  # end

  # defmacro evaluate_doc(document_expression, expected, context) do
  #   quote do
  #     test "Evaluate JSON document \"#{unquote(document_expression) |> String.slice(0, 200)}\"" do
  #       assert unquote(expected) ===
  #                unquote(context)
  #                |> Context.with_json_string(unquote(document_expression))
  #                |> Evaluator.evaluate_arm_document()
  #                |> Map.fetch!(:json)
  #                |> JSONParser.to_elixir()
  #     end
  #   end
  # end

  defmacro parses_to(expression, expected) do
    quote do
      test "ARM expression \"#{unquote(expression) |> String.slice(0, 230)}\"" do
        assert unquote(expected) ===
                 unquote(expression) |> Evaluator.arm_apply(Context.new())
      end
    end
  end

  defmacro parses_to(expression, expected, normalize) do
    quote do
      test "ARM expression \"#{unquote(expression)}\"" do
        assert unquote(expected) |> unquote(normalize).() ===
                 unquote(expression)
                 |> Evaluator.arm_apply(Context.new())
                 |> unquote(normalize).()
      end
    end
  end

  defmacro parses_to_name(expression, expected, test_name) do
    quote do
      test "ARM expression \"#{unquote(test_name)}\"" do
        assert unquote(expected) ===
                 unquote(expression) |> Evaluator.arm_apply(Context.new())
      end
    end
  end

  def eval(expected, input) do
    context = Context.new() |> Context.with_json_string(input)
    assert(expected === Evaluator.arm_apply(context))
  end
end
