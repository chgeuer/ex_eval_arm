defmodule Microsoft.Azure.TemplateLanguageExpressions.UserFunction.Test do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{JSONParser, Evaluator, Context}

  use ExUnit.Case, async: true

  test "evaluate custom function" do
    doc = ~S"""
    {
      "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
      "contentVersion": "2.0.0.0",
      "functions": [
        {
          "namespace": "myNamespace",
          "members": {
            "myOwnFunction": {
              "parameters": [
                { "name": "someString", "type": "string" },
                { "name": "someInteger", "type": "int" }
              ],
              "output": {
                "value": "[concat(parameters('someString'), '-', string(parameters('someInteger')))]",
                "type": "string"
              }
            }
          }
        }
      ]
    }
    """

    myFunc =
      Context.new()
      |> Context.with_json_string(doc)
      |> Context.with_user_parameters(%{})
      |> Evaluator.evaluate_arm_document()
      |> get_in([:functions, "myNamespace.myOwnFunction"])

    assert "hello-321" === myFunc.(["hello", 321])
  end

  test "user function II" do
    json = ~S"""
    {
      "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
      "contentVersion": "2.0.0.0",
      "parameters": {
          "deploymentName": { "type": "string", "defaultValue": "chgp" }
      },
      "variables": {
        "deploymentName": "[parameters('deploymentName')]",
        "names": {
          "postgresql": "[concat(variables('deploymentName'), '-postgresql')]"
        },
        "adminUserName": "[variables('deploymentName')]",
        "connectionString": "[postgresql.createOdbcConnectionString(variables('names').postgresql, 'tenantdata')]"
      },
      "functions": [
        {
          "namespace": "postgresql",
          "members": {
            "createOdbcConnectionString": {
              "parameters": [
                { "name": "server", "type": "string" },
                { "name": "database", "type": "string" }
              ],
              "output": {
                "value": "[concat('Driver={PostgreSQL UNICODE(x64)};Server=', parameters('server'), '.postgres.database.azure.com;Port=5432;Database=', parameters('database'), ';Options=''autocommit=off'';sslmode=require;')]",
                "type": "string"
              }
            }
          }
        }
      ],
      "outputs": {
        "connectionString": { "type": "string", "value": "[variables('connectionString')]" }
      }
    }
    """

    result =
      Context.new()
      |> Context.with_json_string(json)
      |> Context.with_user_parameters(%{})
      |> Evaluator.evaluate_arm_document()
      |> Map.fetch!(:json)
      |> JSONParser.to_elixir()

    assert result === %{
             "$schema" =>
               "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
             "contentVersion" => "2.0.0.0",
             "functions" => [
               %{
                 "members" => %{
                   "createOdbcConnectionString" => %{
                     "output" => %{
                       "type" => "string",
                       "value" =>
                         "[concat('Driver={PostgreSQL UNICODE(x64)};Server=', parameters('server'), '.postgres.database.azure.com;Port=5432;Database=', parameters('database'), ';Options=''autocommit=off'';sslmode=require;')]"
                     },
                     "parameters" => [
                       %{"name" => "server", "type" => "string"},
                       %{"name" => "database", "type" => "string"}
                     ]
                   }
                 },
                 "namespace" => "postgresql"
               }
             ],
             "outputs" => %{
               "connectionString" => %{
                 "type" => "string",
                 "value" =>
                   "Driver={PostgreSQL UNICODE(x64)};Server=chgp-postgresql.postgres.database.azure.com;Port=5432;Database=tenantdata;Options='autocommit=off';sslmode=require;"
               }
             },
             "parameters" => %{
               "deploymentName" => %{
                 "defaultValue" => "chgp",
                 "type" => "string"
               }
             },
             "variables" => %{
               "adminUserName" => "chgp",
               "connectionString" =>
                 "Driver={PostgreSQL UNICODE(x64)};Server=chgp-postgresql.postgres.database.azure.com;Port=5432;Database=tenantdata;Options='autocommit=off';sslmode=require;",
               "deploymentName" => "chgp",
               "names" => %{"postgresql" => "chgp-postgresql"}
             }
           }
  end
end
