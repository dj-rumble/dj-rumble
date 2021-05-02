defmodule DjRumble.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DjRumble.Rooms` context.
  """

  alias DjRumble.Repo
  alias DjRumble.Rooms

  def rooms_fixture(n \\ 2) do
    for _n <- 0..n, do: room_fixture()
  end

  def room_fixture(attrs \\ %{}) do
    random_words = Enum.join(Faker.Lorem.words(5), " ")

    {:ok, room} =
      attrs
      |> Enum.into(%{
        name: random_words,
        slug: random_words
      })
      |> Rooms.create_room()

    room
  end

  def videos_fixture(n \\ 2) do
    for _n <- 0..n, do: video_fixture()
  end

  def video_fixture(attrs \\ %{}) do
    {:ok, video} =
      attrs
      |> Enum.into(%{
        channel_title: "some channel title",
        description: "some description",
        img_height: "420",
        img_url:
          "https://millennialdiyer.com/wp1/wp-content/uploads/2018/11/Tips-Tricks-for-Assigning-Album-Cover-Art-to-your-Music-Library-Default-Image.jpg",
        img_width: "420",
        title: "some title",
        video_id: "YPkp-oESVMM"
      })
      |> Rooms.create_video()

    video
  end

  def room_videos_fixture(%{room: room, videos: videos}, opts \\ %{preload: false}) do
    for video <- videos, do: Rooms.create_room_video(%{room_id: room.id, video_id: video.id})

    case opts.preload do
      false -> %{room: room}
      true -> %{room: Repo.preload(room, :videos)}
    end
  end
end
