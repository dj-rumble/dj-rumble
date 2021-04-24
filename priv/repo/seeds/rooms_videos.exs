require Logger

alias DjRumble.Rooms

schema_upper = "RoomVideo"
schema_plural = "rooms videos"

try do
  rooms = Rooms.list_rooms()
  videos = Rooms.list_videos()

  for {room, index} <- Enum.with_index(rooms) do
    video = Enum.at(videos, index)
    Rooms.create_room_video(%{room_id: room.id, video_id: video.id})
  end
  |> length()
rescue
  Postgrex.Error ->
    Logger.info("#{schema_plural} seeds were already loaded in the database. Skipping execution.")
  error ->
    Logger.error("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.error(error)
    raise error
else
  count ->
    Logger.info("✅ Inserted #{count} #{schema_plural} reationships.")
end
