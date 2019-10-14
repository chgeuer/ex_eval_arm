defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator.Deployment do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-deployment
  alias Microsoft.Azure.TemplateLanguageExpressions.{JSONParser, Evaluator, Context}

  # missing
  # - deployment

  # missing
  # - resourceGroup

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-deployment#variables
  def variables([name], ctx = %Context{json: json}) do
    json
    |> JSONParser.get(["variables", name])
    |> Map.get(:value)
    |> Evaluator.evaluate_node(ctx)
  end

  def parameters([name], %Context{effective_parameters: effective_parameters}) do
    effective_parameters
    |> Map.fetch!(name)
  end
end
