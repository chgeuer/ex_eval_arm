defmodule Microsoft.Azure.TemplateLanguageExpressions.TLEParser.Test do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{TLEParser, Function}
  use ExUnit.Case

  defp parse(input), do: input |> TLEParser.arm() |> unwrap
  defp unwrap({:ok, acc, "", _, _, _}), do: acc
  defp unwrap({:ok, _, rest, _, _, _}), do: {:error, "could not parse" <> rest}
  defp unwrap({:error, reason, _rest, _, _, _}), do: {:error, reason}

  @test_cases %{
    ~S/[a()]/ => %Function{
      name: "a",
      namespace: nil,
      args: [],
      property_path: []
    },
    ~S/[a(1, '', true, '''', -4)]/ => %Function{
      name: "a",
      namespace: nil,
      args: [1, "", true, "'", -4],
      property_path: []
    },
    ~S/[postgreSQL.connectionString( 1, '' ,true, ''''    , -4  , variables('foo').a.b[13].c)[0]]/ =>
      %Function{
        name: "connectionString",
        namespace: "postgreSQL",
        args: [
          1,
          "",
          true,
          "'",
          -4,
          %Function{
            name: "variables",
            namespace: nil,
            args: ["foo"],
            property_path: [property: "a", property: "b", indexer: 13, property: "c"]
          }
        ],
        property_path: [indexer: 0]
      }
  }

  test "expression function 4" do
    assert [
             %Function{
               namespace: nil,
               name: "resourceId",
               args: [
                 %Function{
                   namespace: nil,
                   name: "parameters",
                   args: ["existingVirtualNetworkResourceGroup"],
                   property_path: []
                 },
                 "Microsoft.Network/virtualNetworks/subnets",
                 %Function{
                   namespace: nil,
                   name: "parameters",
                   args: ["existingVirtualNetworkName"],
                   property_path: []
                 },
                 %Function{
                   namespace: nil,
                   name: "parameters",
                   args: ["existingSubnetName"],
                   property_path: []
                 }
               ],
               property_path: []
             }
           ] ==
             ~S<[resourceId(parameters('existingVirtualNetworkResourceGroup'),'Microsoft.Network/virtualNetworks/subnets',parameters('existingVirtualNetworkName'),parameters('existingSubnetName'))]>
             |> parse()
  end

  test "expression boolean" do
    Enum.each(@test_cases, fn {i, o} ->
      assert [o] == i |> parse()
    end)
  end
end
