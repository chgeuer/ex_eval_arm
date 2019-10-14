defmodule Microsoft.Azure.TemplateLanguageExpressions.Context do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{JSONParser, DeploymentContext}

  defstruct json: nil,
            document_source: {:in_memory},
            user_supplied_parameters: %{},
            effective_parameters: %{},
            functions: %{},
            deployment: %DeploymentContext{}

  use Accessible

  def new(), do: %__MODULE__{}

  def with_json_string(context = %__MODULE__{}, content) when is_binary(content),
    do:
      context
      |> Map.put(:document_source, :in_memory)
      |> Map.put(:json, JSONParser.parse(content))

  def with_deployment_context(context = %__MODULE__{}, deploymentContext = %DeploymentContext{}),
    do:
      context
      |> Map.put(:deployment, deploymentContext)

  def with_user_parameters(context = %__MODULE__{}, user_supplied_parameters = %{}) do
    context
    |> Map.put(:user_supplied_parameters, user_supplied_parameters)
  end

  def inject_functions(context = %__MODULE__{}, functions = %{}) do
    functions
    |> Enum.reduce(context, fn {name, f}, ctx ->
      if nil == get_in(ctx, [:functions, name]) do
        put_in(ctx, [:functions, name], f)
      else
        ctx
      end
    end)
  end
end
