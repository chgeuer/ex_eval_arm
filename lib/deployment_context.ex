defmodule Microsoft.Azure.TemplateLanguageExpressions.DeploymentContext do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  defstruct subscriptionId: nil,
            resourceGroup: nil,
            location: nil,
            aad_token_provider: nil

  def with_device_login(context = %__MODULE__{}, %{aad_token_provider: aad_token_provider}) do
    context
    |> Map.put(:aad_token_provider, aad_token_provider)
  end

  use Accessible
end
