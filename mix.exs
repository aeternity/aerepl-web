defmodule AereplServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :aerepl_web,
      version: "5.0.1",
      elixir: "~> 1.15",
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
           syntax_tools: :permanent,
           goldrush: :permanent,
           lager: :permanent,
           gproc: :permanent,
           setup: :permanent,
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
      {:jobs, "~> 0.9"},
      {:parse_trans, "~> 3.4.1", override: :true},
      {:folsom, "~> 1.0.0"},
      {:exometer_core, "~> 1.6.0"},
      {:sext, "~> 1.8.0"},
      {:goldrush, "~> 0.1.9"},
      {:lager, "~> 3.9.2"},
      {:gproc, "~> 0.9.0"},
      {:json, "~> 1.4"},

      { :aerepl,
        git: "https://github.com/aeternity/aerepl",
        tag: "v3.3.2",
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
