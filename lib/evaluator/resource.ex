defmodule Microsoft.Azure.TemplateLanguageExpressions.Evaluator.Resource do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  alias Microsoft.Azure.TemplateLanguageExpressions.{
    Context,
    DeploymentContext,
    REST.RequestBuilder,
    Evaluator.DummyData
  }

  #
  # list* - https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-resource#list
  # listGatewayStatus
  # listKeys
  # listkeys
  # listCredential
  # listCredentials
  # listSasTokens
  # listServiceSas
  # listAccountSas
  # listApiKeys
  #
  def listStar(_), do: {:error, :not_implemented}

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-resource#reference
  def reference(_), do: {:error, :not_implemented}

  # "https://management.azure.com/subscriptions/724467b5-bee4-484b-bf13-d6a5505d2b51/resourceGroups//providers/Microsoft.ManagedIdentity/userAssignedIdentities/chgp-identity?api-version=2018-11-30"

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-resource#resourceid

  def resourceId([resourceType, resourceName1], %Context{
        deployment: %DeploymentContext{
          subscriptionId: subscriptionId,
          resourceGroup: resourceGroupName
        }
      }),
      do: resourceId([subscriptionId, resourceGroupName, resourceType, resourceName1, nil], nil)

  def resourceId([resourceGroupName, resourceType, resourceName1], %Context{
        deployment: %DeploymentContext{subscriptionId: subscriptionId}
      }),
      do: resourceId([subscriptionId, resourceGroupName, resourceType, resourceName1, nil], nil)

  def resourceId([subscriptionId, resourceGroupName, resourceType, resourceName1], _),
    do: resourceId([subscriptionId, resourceGroupName, resourceType, resourceName1, nil], nil)

  def resourceId([nil, _, _, _, _], _), do: {:error, :missing_subscription_id}
  def resourceId([_, nil, _, _, _], _), do: {:error, :missing_resource_group}

  def resourceId(
        [subscriptionId, resourceGroupName, resourceType, resourceName1, resourceName2],
        _
      ) do
    case resourceName2 do
      nil ->
        "/subscriptions/#{subscriptionId}/resourceGroups/#{resourceGroupName}/providers/#{
          resourceType
        }/#{resourceName1}"

      resourceName2 ->
        "/subscriptions/#{subscriptionId}/resourceGroups/#{resourceGroupName}/providers/#{
          resourceType
        }/#{resourceName1}/#{resourceName2}"
    end
  end

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-resource#subscription
  def subscription([], %Context{
        deployment: %DeploymentContext{
          subscriptionId: subscriptionId,
          aad_token_provider: aad_token_provider
        }
      }) do
    %{
      "displayName" => displayName,
      "id" => id,
      "subscriptionId" => subscriptionId,
      "tenantId" => tenantId
    } =
      "https://management.azure.com/subscriptions/#{subscriptionId}?api-version=2019-06-01"
      |> RequestBuilder.call(:get, %{aad_token_provider: aad_token_provider})
      |> Map.fetch!(:body)

    %{
      "displayName" => displayName,
      "id" => id,
      "subscriptionId" => subscriptionId,
      "tenantId" => tenantId
    }
  end

  def reference([resourceId, apiVersion], context) do
    [resourceId, apiVersion, "Full"]
    |> __MODULE__.reference(context)
    |> (fn body ->
          case body do
            %{"properties" => properties} -> properties
            _ -> body
          end
        end).()
  end

  def reference([resourceId, apiVersion, "Full"], %Context{deployment: deployment}) do
    "https://management.azure.com#{resourceId}?api-version=#{apiVersion}"
    |> RequestBuilder.call(:get, deployment)
    |> Map.fetch!(:body)
    |> (fn body ->
      case body do
        #
        # In case of ResourceNotFound, try to fetch dummy data if available
        #
        %{"error" => %{"code" => "ResourceNotFound"} } ->
          [
            "subscriptions", _, "resourceGroups", _,
            "providers", provider, resourceType, _resourceName
          ] = resourceId |> String.split("/", trim: true)

          case DummyData.dummy_data("#{provider}/#{resourceType}") do
            {:error, _} -> body
            dummy_data -> dummy_data
          end

        _ -> body
      end
    end).()
end

  # https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-template-functions-resource#resourcegroup
  def resourceGroup([], %Context{
        deployment:
          deployment = %DeploymentContext{
            subscriptionId: subscriptionId,
            resourceGroup: resourceGroupName
          }
      }) do
    apiVersion = "2019-05-10"

    "https://management.azure.com/subscriptions/#{subscriptionId}/resourceGroups/#{
      resourceGroupName
    }?api-version=#{apiVersion}"
    |> RequestBuilder.call(:get, deployment)
    |> Map.fetch!(:body)
  end
end
