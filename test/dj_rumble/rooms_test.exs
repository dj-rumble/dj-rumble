defmodule DjRumble.RoomsTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase

  alias DjRumble.Rooms

  describe "rooms" do
    alias DjRumble.Rooms.Room

    @valid_attrs %{name: "some name", slug: "some slug"}
    @update_attrs %{name: "some updated name", slug: "some updated slug"}
    @invalid_attrs %{name: nil, slug: nil}

    def room_fixture(attrs \\ %{}) do
      {:ok, room} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rooms.create_room()

      room
    end

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert Rooms.list_rooms() == [room]
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Rooms.get_room!(room.id) == room
    end

    test "get_room_by_slug/1 returns the room with given slug" do
      room = room_fixture()
      assert Rooms.get_room_by_slug(room.slug) == room
    end

    test "create_room/1 with valid data creates a room" do
      assert {:ok, %Room{} = room} = Rooms.create_room(@valid_attrs)
      assert room.name == "some name"
      assert room.slug == "some-slug"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()
      assert {:ok, %Room{} = room} = Rooms.update_room(room, @update_attrs)
      assert room.name == "some updated name"
      assert room.slug == "some-updated-slug"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room(room, @invalid_attrs)
      assert room == Rooms.get_room!(room.id)
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Rooms.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room(room)
    end
  end

  describe "videos" do
    alias DjRumble.Rooms.Video

    @valid_attrs %{
      channel_title: "some channel_title",
      description: "some description",
      img_height: "some img_height",
      img_url: "some img_url",
      img_width: "some img_width",
      title: "some title",
      video_id: "some video_id"
    }
    @update_attrs %{
      channel_title: "some updated channel_title",
      description: "some updated description",
      img_height: "some updated img_height",
      img_url: "some updated img_url",
      img_width: "some updated img_width",
      title: "some updated title",
      video_id: "some updated video_id"
    }
    @invalid_attrs %{
      channel_title: nil,
      description: nil,
      img_height: nil,
      img_url: nil,
      img_width: nil,
      title: nil,
      video_id: nil
    }

    def video_fixture(attrs \\ %{}) do
      {:ok, video} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Rooms.create_video()

      video
    end

    test "list_videos/0 returns all videos" do
      video = video_fixture()
      assert Rooms.list_videos() == [video]
    end

    test "get_video!/1 returns the video with given id" do
      video = video_fixture()
      assert Rooms.get_video!(video.id) == video
    end

    test "create_video/1 with valid data creates a video" do
      assert {:ok, %Video{} = video} = Rooms.create_video(@valid_attrs)
      assert video.channel_title == "some channel_title"
      assert video.description == "some description"
      assert video.img_height == "some img_height"
      assert video.img_url == "some img_url"
      assert video.img_width == "some img_width"
      assert video.title == "some title"
      assert video.video_id == "some video_id"
    end

    test "create_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_video(@invalid_attrs)
    end

    test "update_video/2 with valid data updates the video" do
      video = video_fixture()
      assert {:ok, %Video{} = video} = Rooms.update_video(video, @update_attrs)
      assert video.channel_title == "some updated channel_title"
      assert video.description == "some updated description"
      assert video.img_height == "some updated img_height"
      assert video.img_url == "some updated img_url"
      assert video.img_width == "some updated img_width"
      assert video.title == "some updated title"
      assert video.video_id == "some updated video_id"
    end

    test "update_video/2 with invalid data returns error changeset" do
      video = video_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_video(video, @invalid_attrs)
      assert video == Rooms.get_video!(video.id)
    end

    test "delete_video/1 deletes the video" do
      video = video_fixture()
      assert {:ok, %Video{}} = Rooms.delete_video(video)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_video!(video.id) end
    end

    test "change_video/1 returns a video changeset" do
      video = video_fixture()
      assert %Ecto.Changeset{} = Rooms.change_video(video)
    end
  end

  describe "rooms_videos" do
    alias DjRumble.Rooms.RoomVideo

    def room_video_fixture(attrs \\ %{}) do
      room = room_fixture()
      video = video_fixture()

      {:ok, room_video} =
        attrs
        |> Enum.into(%{room_id: room.id, video_id: video.id})
        |> Rooms.create_room_video()

      room_video
    end

    test "list_rooms_videos/0 returns all rooms_videos" do
      room_video = room_video_fixture()
      assert Rooms.list_rooms_videos() == [room_video]
    end

    test "get_room_video!/1 returns the room_video with given id" do
      room_video = room_video_fixture()
      assert Rooms.get_room_video!(room_video.id) == room_video
    end

    test "create_room_video/1 with valid data creates a room_video" do
      room = room_fixture()
      video = video_fixture()

      assert {:ok, %RoomVideo{} = _room_video} =
               Rooms.create_room_video(%{room_id: room.id, video_id: video.id})
    end

    test "create_room_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room_video(@invalid_attrs)
    end

    test "update_room_video/2 with valid data updates the room_video" do
      room_video = room_video_fixture()
      room = room_fixture(%{slug: "some unique slug"})
      video = video_fixture()

      assert {:ok, %RoomVideo{} = _room_video} =
               Rooms.update_room_video(room_video, %{room_id: room.id, video_id: video.id})
    end

    test "update_room_video/2 with invalid data returns error changeset" do
      room_video = room_video_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room_video(room_video, @invalid_attrs)
      assert room_video == Rooms.get_room_video!(room_video.id)
    end

    test "delete_room_video/1 deletes the room_video" do
      room_video = room_video_fixture()
      assert {:ok, %RoomVideo{}} = Rooms.delete_room_video(room_video)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room_video!(room_video.id) end
    end

    test "change_room_video/1 returns a room_video changeset" do
      room_video = room_video_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room_video(room_video)
    end
  end
end
