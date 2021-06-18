defmodule DjRumble.Collections.UserRoomVideo do
  @moduledoc """
  Defines a user room video relationship
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_rooms_videos" do
    belongs_to :user, DjRumble.Accounts.User
    belongs_to :room, DjRumble.Rooms.Room
    belongs_to :video, DjRumble.Rooms.Video

    timestamps()
  end

  @fields [:user_id, :room_id, :video_id]

  @doc false
  def changeset(user_room_video, attrs) do
    user_room_video
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
