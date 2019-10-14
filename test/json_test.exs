defmodule Microsoft.Azure.TemplateLanguageExpressions.JSONParser.Test do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{Context, Evaluator, JSONParser, DeploymentContext}
  import Microsoft.Azure.TemplateLanguageExpressions.TestHelper,
    only: [json_roundtrip: 2, evaluate_node: 2, evaluate_doc: 2]
  use ExUnit.Case, async: true

  @expected %{}
  ~s/{}/ |> json_roundtrip(@expected)
  ~s/{} / |> json_roundtrip(@expected)
  ~s/ {} / |> json_roundtrip(@expected)
  ~s/ {}/ |> json_roundtrip(@expected)
  ~s/ { }/ |> json_roundtrip(@expected)
  ~s/ { \t}/ |> json_roundtrip(@expected)

  ~s"""

  // A JSON doc
  // can contain

  /* one */ /* or more*/
  // single
  /* and
     multi
     line */

  {
    // actually, many comments and just a single object
  }

  // you
  /*
  understand
  */
  //?

  """
  |> json_roundtrip(@expected)

  @expected []
  ~s/[]/ |> json_roundtrip(@expected)
  ~s/[] / |> json_roundtrip(@expected)
  ~s/ [] / |> json_roundtrip(@expected)
  ~s/ []/ |> json_roundtrip(@expected)
  ~s/ [ ]/ |> json_roundtrip(@expected)
  ~s/ [ \t]/ |> json_roundtrip(@expected)

  ~s/ [ \t { }]/ |> json_roundtrip([%{}])

  @expected %{"a" => 1}
  ~s/{"a":1}/ |> json_roundtrip(@expected)
  ~s/{"a":1 }/ |> json_roundtrip(@expected)
  ~s/{"a": 1}/ |> json_roundtrip(@expected)
  ~s/{"a": 1 }/ |> json_roundtrip(@expected)
  ~s/{"a" :1}/ |> json_roundtrip(@expected)
  ~s/{"a" :1 }/ |> json_roundtrip(@expected)
  ~s/{"a" : 1}/ |> json_roundtrip(@expected)
  ~s/{"a" : 1 }/ |> json_roundtrip(@expected)
  ~s/{ "a":1}/ |> json_roundtrip(@expected)
  ~s/{ "a":1 }/ |> json_roundtrip(@expected)
  ~s/{ "a": 1}/ |> json_roundtrip(@expected)
  ~s/{ "a": 1 }/ |> json_roundtrip(@expected)
  ~s/{ "a" :1}/ |> json_roundtrip(@expected)
  ~s/{ "a" :1 }/ |> json_roundtrip(@expected)
  ~s/{ "a" : 1}/ |> json_roundtrip(@expected)
  ~s/{ "a" : 1 }/ |> json_roundtrip(@expected)

  @expected 1
  ~s/1/ |> json_roundtrip(@expected)
  ~s/1 / |> json_roundtrip(@expected)
  ~s/ 1 \t/ |> json_roundtrip(@expected)

  ~s/ true \t/ |> json_roundtrip(true)
  ~s/12345/ |> json_roundtrip(12345)
  ~s/3.1415/ |> json_roundtrip(3.1415)
  ~s/0.31415e1/ |> json_roundtrip(3.1415)
  ~s/{ "a" : [] }/ |> json_roundtrip(%{"a" => []})
  ~s/{ "a" : [ ] }/ |> json_roundtrip(%{"a" => []})
  ~s/{ "a" : [ 1\t] }/ |> json_roundtrip(%{"a" => [1]})
  ~s/{ "a" : [ 1\t, "22", true] }/ |> json_roundtrip(%{"a" => [1, "22", true]})
  ~s/ [  true,    false] \t/ |> json_roundtrip([true, false])
  ~s/ [  [[\t[[\t[[\t[\t\t]   ]] ] ] ]   \t ]] \t/ |> json_roundtrip([[[[[[[[]]]]]]]])

  ~s"""
    /* funky   */ \t

    // really

     [    // awesome
       /* little test */   {  // awesome
         /* wow */
       }   /* wow nore */
     ]//incredible

    /*
     *
     * more
     */ \r\n\r\n\r\n
     // how cool is that
     // really cool I ...
     /* ... believe */
  """
  |> json_roundtrip([%{}])

  ~S/{ "a": "[1]" }/ |> evaluate_node(%{"a" => 1})

  ~S/{ "a": [ "[1]", true, "[true]", "[createArray(1, 2, 3)]"  ], "b": "[json('{\"c\": 1}')]" }/
  |> evaluate_node(%{"a" => [1, true, true, [1, 2, 3]], "b" => %{"c" => 1}})

  ~S/1/ |> evaluate_node(1)
  ~S/"[1]"/ |> evaluate_node(1)
  ~S/"['foo']"/ |> evaluate_node("foo")

  ~S"""
  {
    "variables": {
      "a": "[15]",
      "b": "[add(13, variables('a'))]",
      "c": [ "[concat('hallo', ' ', string(variables('b')))]", 1 ],
      "d": {
        "d1": 1,
        "d2": {
          "e": 3
        }
      },
      "f": "[add(variables('d').d2.e, 1)]"
    }
  }
  """
  |> evaluate_doc(%{
    "variables" => %{
      "a" => 15,
      "b" => 28,
      "c" => ["hallo 28", 1],
      "d" => %{"d1" => 1, "d2" => %{"e" => 3}},
      "f" => 4
    }
  })

  ~S"""
  {
    "variables": {
      "a": "[15]",
      "b": "[add(13, variables('a'))]",
      "c": [ "[concat('hallo', ' ', string(variables('b')))]", 1 ],
      "d": {
        "d1": 1,
        "d2": {
          "e": [0,1, 2, 3 ]
        }
      },
      "f": "[add(variables('d').d2.e[3], 1)]"
    }
  }
  """
  |> evaluate_doc(%{
    "variables" => %{
      "a" => 15,
      "b" => 28,
      "c" => ["hallo 28", 1],
      "d" => %{"d1" => 1, "d2" => %{"e" => [0, 1, 2, 3]}},
      "f" => 4
    }
  })

  test "eval_params" do
    json = """
      {
      "parameters": {
        "a": { "type": "integer", "defaultValue": 19 },
        "b": { "type": "integer" }
      },
      "variables": {
        "a": "[add(parameters('a'), parameters('b'))]"
      }
    }
    """

    assert Context.new()
           |> Context.with_json_string(json)
           |> Context.with_user_parameters(%{"b" => 2000})
           |> Evaluator.evaluate_arm_document()
           |> Map.fetch!(:json)
           |> JSONParser.to_elixir() === %{
             "parameters" => %{
               "a" => %{"type" => "integer", "defaultValue" => 19},
               "b" => %{"type" => "integer"}
             },
             "variables" => %{"a" => 2019}
           }
  end

  # test "subscription()" do
  #   json = """
  #   {
  #     "variables": {
  #       "sub": "[subscription()]"
  #     }
  #   }
  #   """

  #   assert Context.new()
  #          |> Context.with_json_string(json)
  #          |> Evaluator.evaluate_arm_document()
  #          |> Map.fetch!(:json)
  #          |> JSONParser.to_elixir() === %{
  #            "variables" => %{
  #              "sub" => %{
  #                "tenantId" => "942023a6-efbe-4d97-a72d-532ef7337595",
  #                "id" => "/subscriptions/724467b5-bee4-484b-bf13-d6a5505d2b51",
  #                "subscriptionId" => "724467b5-bee4-484b-bf13-d6a5505d2b51",
  #                "displayName" => "chgeuer-work"
  #              }
  #            }
  #          }
  # end

  test "resourceid()" do
    json = """
    {
      "variables": {
        "nsg1": "[resourceId('Microsoft.Network/networkSecurityGroups', 'nsg1')]",
        "nsg2": "[resourceId('rg2', 'Microsoft.Network/networkSecurityGroups', 'nsg2')]",
        "nsg3": "[resourceId('deafbeef-1234-5678-9abc-def000011111', 'rg3', 'Microsoft.Network/networkSecurityGroups', 'nsg3')]",
        "nsg4": "[resourceId('deafbeef-1234-5678-9abc-def000011111', 'rg3', 'Microsoft.Network/networkSecurityGroups', 'nsg3', 'more')]"
      }
    }
    """

    assert Context.new()
           |> Context.with_json_string(json)
           |> Context.with_deployment_context(%DeploymentContext{
             subscriptionId: "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
             resourceGroup: "rg1"
           })
           |> Evaluator.evaluate_arm_document()
           |> Map.fetch!(:json)
           |> JSONParser.to_elixir() === %{
             "variables" => %{
               "nsg1" =>
                 "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg1/providers/Microsoft.Network/networkSecurityGroups/nsg1",
               "nsg2" =>
                 "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg2/providers/Microsoft.Network/networkSecurityGroups/nsg2",
               "nsg3" =>
                 "/subscriptions/deafbeef-1234-5678-9abc-def000011111/resourceGroups/rg3/providers/Microsoft.Network/networkSecurityGroups/nsg3",
               "nsg4" =>
                 "/subscriptions/deafbeef-1234-5678-9abc-def000011111/resourceGroups/rg3/providers/Microsoft.Network/networkSecurityGroups/nsg3/more"
             }
           }
  end
end
