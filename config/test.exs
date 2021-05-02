use Mix.Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :dj_rumble, DjRumble.Repo,
  username: System.get_env("DB_USERNAME_TEST"),
  password: System.get_env("DB_PASSWORD_TEST"),
  database: "dj_rumble_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  timeout: :infinity

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dj_rumble, DjRumbleWeb.Endpoint,
  http: [port: 4002],
  server: false

config :dj_rumble, DjRumble.Mailer,
  adapter: Bamboo.TestAdapter

# Print only warnings and errors during test
config :logger, level: :warn
