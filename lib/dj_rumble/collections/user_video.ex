defmodule DjRumble.Collections.UserVideo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_videos" do
    belongs_to :user, DjRumble.Accounts.User
    belongs_to :video, DjRumble.Rooms.Video

    timestamps()
  end

  @doc false
  def changeset(user_video, attrs) do
    user_video
    |> cast(attrs, [:user_id, :video_id])
    |> validate_required([:user_id, :video_id])
  end
end
