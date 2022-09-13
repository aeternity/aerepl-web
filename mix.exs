defmodule AereplHttp.MixProject do
  use Mix.Project

  def project do
    [
      app: :aerepl_http,
      version: "2.1.3",
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
      mod: {AereplHttp.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib", "deps/aerepl/_build/prod/lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
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
      {
        :aerepl,
        git: "https://github.com/aeternity/aerepl",
        tag: "v2.3.0",
        app: false,
        compile: "make",
        manager: :make
      }
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      # "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      # "ecto.reset": ["ecto.drop", "ecto.setup"],
      # test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
