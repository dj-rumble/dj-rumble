defmodule DjRumble.Rooms.Video do
  use Ecto.Schema
  import Ecto.Changeset

  schema "videos" do
    field :channel_title, :string
    field :description, :string
    field :img_height, :string
    field :img_url, :string
    field :img_width, :string
    field :title, :string
    field :video_id, :string

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [:video_id, :title, :description, :channel_title, :img_url, :img_height, :img_width])
    |> validate_required([:video_id, :title, :description, :channel_title, :img_url, :img_height, :img_width])
  end
end
