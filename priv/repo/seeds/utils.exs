defmodule DjRumble.Seeds.Utils do

  alias DjRumble.Collections
  alias DjRumble.Repo
  alias DjRumble.Rooms

  def date_to_naive_datetime("NULL"), do: nil
  def date_to_naive_datetime(datetime) do
    {:ok, naive_datetime} = Ecto.Type.cast(:naive_datetime, datetime)
    naive_datetime
  end

  def dates_to_naive_datetime(map, keys) do
    Enum.reduce(keys, %{}, fn (key, acc) ->
      Map.put(acc, key, date_to_naive_datetime(Map.get(map, key)))
    end)
  end

  def create_room(room) do
    room = Map.merge(
      room,
      dates_to_naive_datetime(room, [:inserted_at, :updated_at])
    )
    {:ok, room} = Rooms.create_room(room)
    room
  end

  def create_videos(videos) do
    for video <- videos do
      {:ok, video} = Map.merge(
        video,
        dates_to_naive_datetime(video, [:inserted_at, :updated_at])
      )
      |> Rooms.create_video()
      video
    end
  end

  def create_user_room_videos(user_id, room_id, videos_ids) do
    for video_id <- videos_ids do
      {:ok, user_room_video} = Collections.create_user_room_video(%{room_id: room_id, user_id: user_id, video_id: video_id})
      user_room_video
    end
  end

end
