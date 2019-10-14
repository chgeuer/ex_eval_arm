defmodule Microsoft.ARM.Evaluator.MixProject do
  # Copyright (c) Microsoft Corporation.
  # Licensed under the MIT License.
  use Mix.Project

  def project do
    [
      app: :microsoft_arm_evaluator,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        demo: [
          include_executables_for: [:windows],
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      applications: [:tesla, :ibrowse],
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:nimble_parsec, "~> 0.5.1"},
      {:poison, ">= 1.0.0"},
      {:exdatauri, "~> 0.2.0"},
      {:uuid, "~> 1.1"},
      {:timex, "~> 3.6"},
      # needed for `mix test`
      {:tzdata, "~> 0.1.8", override: true},
      {:accessible, "~> 0.2.1"},
      {:file_system, "~> 0.2.7"},
      {:ibrowse, "~> 4.4"},
      {:tesla, "~> 0.8"},
      {:ex_microsoft_azure_utils, github: "chgeuer/ex_microsoft_azure_utils"}
    ]
  end
end
