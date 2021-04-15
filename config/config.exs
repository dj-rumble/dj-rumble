# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :dj_rumble,
  ecto_repos: [DjRumble.Repo]

# Configures the endpoint
config :dj_rumble, DjRumbleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MhOgAXMPXPUxdbTLzi4ZZivA7CO4Jq7DiTmQ8Zl2TvAITUHB8azsJgAFdnpMWvoi",
  render_errors: [view: DjRumbleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: DjRumble.PubSub,
  live_view: [signing_salt: "ZzPmaVMZ"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
