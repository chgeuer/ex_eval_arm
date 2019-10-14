defmodule Microsoft.Azure.TemplateLanguageExpressions.Function do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  @derive {Inspect, except: [:property_path]}
  defstruct [:name, :namespace, :args, :property_path]

  def full_name(%__MODULE__{namespace: nil, name: name}), do: name
  def full_name(%__MODULE__{namespace: namespace, name: name}), do: "#{namespace}.#{name}"
end
