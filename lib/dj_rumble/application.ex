defmodule DjRumble.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      DjRumble.Repo,
      # Start the Telemetry supervisor
      DjRumbleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: DjRumble.PubSub},
      # Start the Endpoint (http/https)
      DjRumbleWeb.Endpoint,
      # Starts the Presence service
      DjRumbleWeb.Presence,
      # Starts the Rooms service
      DjRumble.Rooms,
      DjRumble.Rounds
      # Start a worker by calling: DjRumble.Worker.start_link(arg)
      # {DjRumble.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DjRumble.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    DjRumbleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
