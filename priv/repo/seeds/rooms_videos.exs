require Logger

alias DjRumble.Rooms

schema_upper = "RoomVideo"
schema_plural = "rooms videos"

try do
  rooms = Rooms.list_rooms()
  videos = Rooms.list_videos()
  single_video_rooms = Enum.with_index(Enum.take(rooms, 3))
  multi_video_room = Enum.at(rooms, -1)
  vulf_videos = Enum.with_index(Enum.take(videos, -6))

  for {video, video_index} <- vulf_videos do
    Rooms.create_room_video(%{room_id: multi_video_room.id, video_id: video.id})
  end

  for {room, room_index} <- single_video_rooms do
    video = Enum.at(videos, room_index)
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
