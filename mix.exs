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
          applications: [runtime_tools: :permanent]
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
  defp elixirc_paths(_), do: ["lib", "deps/aerepl/_build/prod/rel/aerepl/lib"]

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

      { :aebytecode,
        git: "https://github.com/aeternity/aebytecode.git",
        tag: "v3.3.0",
        compile: "make",
        manager: :rebar3,
        override: true
      },
      { :aerepl,
        git: "https://github.com/aeternity/aerepl",
        # tag: "v3.0.0",
        branch: "fs-cache",
        app: false,
        compile: "make",
        manager: :rebar3,
      }

    ]
  end

  defp aliases do
    []
  end
end
