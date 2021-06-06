defmodule DjRumble.Rooms.Room do
  @moduledoc """
  Responsible for declaring the Room schema and rooms management
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :name, :string
    field :slug, :string

    many_to_many :videos, DjRumble.Rooms.Video, join_through: "rooms_videos"

    many_to_many :users, DjRumble.Accounts.User, join_through: DjRumble.Rooms.UserRoom

    has_many :users_rooms_videos, DjRumble.Collections.UserRoomVideo

    timestamps()
  end

  @fields [:name, :slug]

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, @fields)
    |> validate_required([:name, :slug])
    |> format_slug()
    |> unique_constraint(:slug)
  end

  defp format_slug(%Ecto.Changeset{changes: %{slug: _}} = changeset) do
    changeset
    |> update_change(:slug, fn slug ->
      slug
      |> String.downcase()
      |> String.replace(" ", "-")
    end)
  end

  defp format_slug(changeset), do: changeset
end
