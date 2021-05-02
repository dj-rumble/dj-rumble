defmodule DjRumble.MixProject do
  use Mix.Project

  def project do
    [
      app: :dj_rumble,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {DjRumble.Application, []},
      extra_applications: [:logger, :runtime_tools, :bamboo]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 1.6"},
      {:bcrypt_elixir, "~> 2.0"},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.4"},
      {:excoveralls, "~> 0.10", only: :test},
      {:faker, "~> 0.16"},
      {:floki, ">= 0.27.0"},
      {:gettext, "~> 0.11"},
      {:git_hooks, "~> 0.6.2", only: [:dev], runtime: false},
      {:jason, "~> 1.0"},
      {:phoenix, "~> 1.5.8"},
      {:phoenix_ecto, "~> 4.1"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_inline_svg, "~> 1.4"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.15.1"},
      {:plug_cowboy, "~> 2.0"},
      {:sobelow, "~> 0.11", only: [:dev, :test], runtime: false},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      eslint: ["cmd npm run eslint --prefix assets"],
      "eslint.fix": ["cmd npm run eslint-fix --prefix assets"]
    ]
  end
end
