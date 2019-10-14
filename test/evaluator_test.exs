defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator.Test do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  import Microsoft.Azure.TemplateLanguageExpressions.TestHelper,
    only: [parses_to: 2, parses_to: 3, parses_to_name: 3]

  use ExUnit.Case, async: true

  @external_resource Path.join([__DIR__, "static_tests.json"])

  with {:ok, body} <- File.read(Path.join([__DIR__, "static_tests.json"])),
       {:ok, json} <- Poison.decode(body) do
    Enum.each(json, fn {expression, result} ->
      @expression expression
      @result result

      @expression |> parses_to(@result)
    end)
  end

  #
  # Error handling
  #
  ~S/[int('1s3')]/ |> parses_to("Cannot parse int('1s3')")
  ~S/[length(true)]/ |> parses_to({:error, :need_string_or_array_or_object})
  ~S/[length(2)]/ |> parses_to({:error, :need_string_or_array_or_object})
  ~S/[range()]/ |> parses_to({:error, :need_two_integers})
  ~S/[range(2)]/ |> parses_to({:error, :need_two_integers})
  ~S/[range(2,true)]/ |> parses_to({:error, :need_two_integers})
  ~S/[range('a', 4)]/ |> parses_to({:error, :need_two_integers})
  ~S/[json('"foo')]/ |> parses_to({:error, :json_parse_error})
  ~S/[json('12a')]/ |> parses_to({:error, :json_parse_error})
  ~S/[json('{')]/ |> parses_to({:error, :json_parse_error})
  ~S/[json(2)]/ |> parses_to({:error, :need_string})
  ~S/[json(true)]/ |> parses_to({:error, :need_string})
  ~S/[concat(1, 2)]/ |> parses_to({:error, :need_string_or_array_or_object})
  ~S/[contains(1, 2)]/ |> parses_to({:error, :unsupported_args})
  ~S/[first('')]/ |> parses_to({:error, :need_non_empty_list_or_string})
  ~S/[first(createArray())]/ |> parses_to({:error, :need_non_empty_list_or_string})
  ~S/[last('')]/ |> parses_to({:error, :need_non_empty_list_or_string})
  ~S/[last(createArray())]/ |> parses_to({:error, :need_non_empty_list_or_string})
  ~S/[union(1, 'foo')]/ |> parses_to({:error, :unsupported_args})
  ~S/[greater('a', 'A')]/ |> parses_to({:error, :not_implemented_unclear_specification})
  ~S/[greaterOrEquals('a', 'A')]/ |> parses_to({:error, :not_implemented_unclear_specification})
  ~S/[less('a', 'A')]/ |> parses_to({:error, :not_implemented_unclear_specification})
  ~S/[lessOrEquals('a', 'A')]/ |> parses_to({:error, :not_implemented_unclear_specification})
  ~S/[array(true, 2)]/ |> parses_to({:error, :requires_single_argument})
  ~S/[take('one two three')]/ |> parses_to({:error, :need_string_or_array_and_integer})
  ~S/[take('one two three', true)]/ |> parses_to({:error, :need_string_or_array_and_integer})
  ~S/[skip('one two three')]/ |> parses_to({:error, :need_string_or_array_and_integer})
  ~S/[skip('one two three', true)]/ |> parses_to({:error, :need_string_or_array_and_integer})

  ~S/[intersection(json('["one", "two", "three"]'), json('["three", "four", "two"]'))]/
  |> parses_to(["two", "three"], &Enum.sort/1)

  ~S/[intersection(range(0, 100), range(30, 10), range(2, 1000), range(20, 60))]/
  |> parses_to(Enum.into(30..39, []))

  ~S/[union(json('["one", "two", "three"]'), json('["three", "four"]'))]/
  |> parses_to(["one", "two", "three", "four"], &Enum.sort/1)

  ~S/[string(json('{ "valueA": 10, "valueB": "Example Text" }'))]/
  |> parses_to(~S/{"valueA":10, "valueB":"Example Text"}/, &Poison.decode!/1)

  @o ~S/json('{"null":null,"string":"default","int":1,"object":{"first":"default"},"array":[1]}')/
  ~s/[coalesce(#{@o}.null, #{@o}.null, #{@o}.string)]/
  |> parses_to_name("default", ~S/[coalesce()] with string/)

  ~s/[coalesce(#{@o}.null, #{@o}.null, #{@o}.int)]/
  |> parses_to_name(1, ~S/[coalesce()] with int/)

  ~s/[coalesce(#{@o}.null, #{@o}.null, #{@o}.object)]/
  |> parses_to_name(%{"first" => "default"}, ~S/[coalesce()] with object/)

  ~s/[coalesce(#{@o}.null, #{@o}.null, #{@o}.array)]/
  |> parses_to_name([1], ~S/[coalesce()] with array/)

  ~s/[coalesce(#{@o}.null, #{@o}.null)]/ |> parses_to_name(nil, ~S/[coalesce()] with nil/)
  # ~S/[newGuid()]/ |> parses_to("")
end
