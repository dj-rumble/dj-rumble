defmodule DjRumble.Rooms.Video do
  @moduledoc """
  Responsible for declaring the Video schema and videos management
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias DjRumble.Rooms.Video

  schema "videos" do
    field :channel_title, :string
    field :description, :string
    field :img_height, :string
    field :img_url, :string
    field :img_width, :string
    field :title, :string
    field :video_id, :string

    many_to_many :rooms, DjRumble.Rooms.Room, join_through: "rooms_videos"
    many_to_many :users, DjRumble.Accounts.User, join_through: "users_videos"

    timestamps()
  end

  @doc false
  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :video_id,
      :title,
      :description,
      :channel_title,
      :img_url,
      :img_height,
      :img_width
    ])
    |> validate_required([
      :video_id,
      :title,
      :channel_title,
      :img_url,
      :img_height,
      :img_width
    ])
  end

  def video_placeholder(attrs \\ %{}) do
    attrs =
      Enum.into(
        attrs,
        %{
          channel_title: "",
          description: "",
          img_height: "120",
          img_url:
            "http://journey.coca-cola.com/content/dam/journey/lc/es/private/cultura/2018/5-mayo/Portada-vinyl--1-.gif",
          img_width: "120",
          title: "",
          video_id: ""
        }
      )

    struct(Video, attrs)
  end

  def from_tubex(tubex_video) do
    %Video{
      channel_title: HtmlEntities.decode(tubex_video.channel_title),
      description: HtmlEntities.decode(tubex_video.description),
      img_height: "#{tubex_video.thumbnails["default"]["height"]}",
      img_url: tubex_video.thumbnails["default"]["url"],
      img_width: "#{tubex_video.thumbnails["default"]["width"]}",
      title: HtmlEntities.decode(tubex_video.title),
      video_id: tubex_video.video_id
    }
  end
end
