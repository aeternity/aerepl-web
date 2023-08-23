defmodule AereplServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :aerepl_web,
      version: "2.2.0",
      elixir: "~> 1.13.2",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        app: [
          include_executables_for: [:unix],
          applications:
          [runtime_tools: :permanent,
           syntax_tools: :none,
           goldrush: :none,
           lager: :none,
           gproc: :none,
           setup: :none,
          ]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {AereplServer.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.5.9"},
      {:phoenix_pubsub, "~> 2.1.1"},
      {:phoenix_html, "~> 3.2.0"},
      {:phoenix_live_reload, "~> 1.3.3", only: :dev},
      {:jason, "~> 1.3.0"},
      {:plug_cowboy, "~> 2.5.2"},
      {:credo, "~> 1.6.6", only: [:dev, :test]},
      {:dogma, "~> 0.1", only: [:dev]},
      {:telemetry, "~> 1.1.0"},
      {:uuid, "~> 1.1"},
      {:jobs, "~> 0.7"},
      {:folsom, "~> 1.0.0"},
      {:exometer_core, "~> 1.6.0"},

      { :aerepl,
        git: "https://github.com/aeternity/aerepl",
        # tag: "v3.0.0",
        branch: "fs-cache",
        app: false,
        compile: "make",
        manager: :make,
      }
    ]
  end

  defp aliases do
    []
  end
end
