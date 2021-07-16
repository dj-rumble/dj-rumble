Code.require_file("utils.exs", __DIR__)

require Logger

alias DjRumble.Accounts.User
alias DjRumble.Repo
alias DjRumble.Seeds.Utils

schema_upper = "UserRoomVideo"

json_file = "#{__DIR__}/rooms_videos.json"

try do
  with {:ok, body} <- File.read(json_file),
    {:ok, rooms_videos} <- Jason.decode(body, keys: :atoms) do

    user_ids = Repo.all(User)
    |> Enum.map(& &1.id)

    for %{room: room, videos: videos} <- rooms_videos do
      room_id = Utils.create_room(room).id
      videos_ids = Utils.create_videos(videos)
      |> Enum.map(& &1.id)

      Utils.create_user_room_videos(user_ids, room_id, videos_ids)

      {1, length(videos_ids)}
    end
    |> Enum.reduce({0, 0}, fn {1, videos_length}, {rooms_count, videos_count} ->
      {rooms_count + 1, videos_count + videos_length}
    end)
  end
rescue
  Postgrex.Error ->
    Logger.info("#{schema_upper} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.info("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.info(error)
    raise error
else
  {rooms_count, videos_count} ->
    Logger.info("✅ Inserted #{rooms_count} Rooms and #{videos_count} Videos")
end
