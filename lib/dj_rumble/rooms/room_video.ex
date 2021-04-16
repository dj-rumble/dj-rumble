defmodule DjRumble.Rooms.RoomVideo do
  use Ecto.Schema
  import Ecto.Changeset
  alias DjRumble.Rooms.{Room, Video}

  schema "rooms_videos" do
    belongs_to :room, Room
    belongs_to :video, Video

    timestamps()
  end

  @doc false
  def changeset(room_video, attrs) do
    room_video
    |> cast(attrs, [:room_id, :video_id])
    |> validate_required([:room_id, :video_id])
  end
end
