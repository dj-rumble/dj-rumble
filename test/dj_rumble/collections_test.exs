defmodule DjRumble.CollectionsTest do
  @moduledoc """
  Tests for the Collections context
  """
  use DjRumble.DataCase

  alias DjRumble.Collections

  describe "users_rooms_videos" do
    import DjRumble.AccountsFixtures
    import DjRumble.RoomsFixtures

    alias DjRumble.Collections.UserRoomVideo

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{user_id: nil}

    def user_room_video_fixture(attrs \\ %{}) do
      user = user_fixture()
      room = room_fixture()
      video = video_fixture()

      {:ok, user_room_video} =
        attrs
        |> Enum.into(%{user_id: user.id, room_id: room.id, video_id: video.id})
        |> Collections.create_user_room_video()

      user_room_video
    end

    @tag wip: true
    test "list_users_rooms_videos/0 returns all users_rooms_videos" do
      user_room_video = user_room_video_fixture()
      assert Collections.list_users_rooms_videos() == [user_room_video]
    end

    @tag wip: true
    test "get_user_room_video!/1 returns the user_room_video with given id" do
      user_room_video = user_room_video_fixture()
      assert Collections.get_user_room_video!(user_room_video.id) == user_room_video
    end

    @tag wip: true
    test "create_user_room_video/1 with valid data creates a user_room_video" do
      user = user_fixture()
      room = room_fixture()
      video = video_fixture()

      valid_attrs =
        Enum.into(@valid_attrs, %{room_id: room.id, user_id: user.id, video_id: video.id})

      assert {:ok, %UserRoomVideo{} = user_room_video} =
               Collections.create_user_room_video(valid_attrs)
    end

    @tag wip: true
    test "create_user_room_video/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Collections.create_user_room_video(@invalid_attrs)
    end

    @tag wip: true
    test "update_user_room_video/2 with valid data updates the user_room_video" do
      user_room_video = user_room_video_fixture()

      assert {:ok, %UserRoomVideo{} = user_room_video} =
               Collections.update_user_room_video(user_room_video, @update_attrs)
    end

    @tag wip: true
    test "update_user_room_video/2 with invalid data returns error changeset" do
      user_room_video = user_room_video_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Collections.update_user_room_video(user_room_video, @invalid_attrs)

      assert user_room_video == Collections.get_user_room_video!(user_room_video.id)
    end

    @tag wip: true
    test "delete_user_room_video/1 deletes the user_room_video" do
      user_room_video = user_room_video_fixture()
      assert {:ok, %UserRoomVideo{}} = Collections.delete_user_room_video(user_room_video)

      assert_raise Ecto.NoResultsError, fn ->
        Collections.get_user_room_video!(user_room_video.id)
      end
    end

    @tag wip: true
    test "change_user_room_video/1 returns a user_room_video changeset" do
      user_room_video = user_room_video_fixture()
      assert %Ecto.Changeset{} = Collections.change_user_room_video(user_room_video)
    end
  end
end
