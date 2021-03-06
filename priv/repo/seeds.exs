# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     DjRumble.Repo.insert!(%DjRumble.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
require Logger

try do
  seeds = [
    "users",
    "rooms_videos"
  ]

  for seed <- seeds do
    Code.require_file("seeds/#{seed}.exs", __DIR__)
  end
rescue
  error ->
    Logger.error(error)
    Logger.info("❌ Stopped seeds population due to errors.")
else
  _ ->
    Logger.info("🌱 Seeds population finished succesfully")
end
