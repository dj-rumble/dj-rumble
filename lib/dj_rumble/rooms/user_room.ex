defmodule DjRumble.Rooms.UserRoom do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users_rooms" do
    belongs_to :user, DjRumble.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(user_room, attrs) do
    user_room
    |> cast(attrs, [:user_id, :room_id, :group_id, :is_owner])
    |> validate_required([:user_id, :room_id, :group_id, :is_owner])
  end
end
