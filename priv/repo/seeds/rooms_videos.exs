require Logger

alias DjRumble.Rooms

schema_upper = "RoomVideo"
schema_plural = "rooms videos"

# This script assumes the videos and rooms seeds have already been loaded.
try do
  # Fetches current rooms and videos
  room_ids = Rooms.list_rooms() |> Enum.map(fn room -> room.id end)
  video_ids = Rooms.list_videos() |> Enum.map(fn video -> video.id end)
  single_video_rooms = Enum.with_index(Enum.take(room_ids, 3))
  vulf_video_ids = Enum.slice(video_ids, length(single_video_rooms), 6)
  short_video_ids = Enum.slice(video_ids, length(single_video_rooms) + length(vulf_video_ids), 10)

  for room_id <- room_ids do
    video_ids =
      case room_id do
        1 -> [Enum.at(video_ids, 0)]
        2 -> [Enum.at(video_ids, 1)]
        3 -> [Enum.at(video_ids, 2)]
        4 -> vulf_video_ids
        5 -> short_video_ids
      end
    for video_id <- video_ids, do: {room_id, video_id}
  end
  |> List.flatten()
  |> Enum.map(fn {room_id, video_id} ->
    {:ok, room_video} = Rooms.create_room_video(%{room_id: room_id, video_id: video_id})
    room_video
  end)
  |> length()
rescue
  Postgrex.Error ->
    Logger.info("#{schema_plural} seeds were already loaded in the database. Skipping execution.")
  error ->
    IO.inspect(error)
    Logger.error("❌ Unexpected error while loading #{schema_upper} seeds.")
    Logger.error(error)
    raise error
else
  count ->
    Logger.info("✅ Inserted #{count} #{schema_plural} reationships.")
end
