defmodule DefinitionAggregate.MixProject do
  use Mix.Project

  def project do
    [
      app: :definition_aggregate,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.3", only: [:dev]},
      {:definition, in_umbrella: true},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:protocol_decoder, in_umbrella: true},
      {:protocol_destination, in_umbrella: true},
      {:protocol_source, in_umbrella: true}
    ]
  end
end