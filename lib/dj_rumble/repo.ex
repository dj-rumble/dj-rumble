defmodule DjRumble.Repo do
  use Ecto.Repo,
    otp_app: :dj_rumble,
    adapter: Ecto.Adapters.Postgres
end
