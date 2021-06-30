defmodule DjRumble.Support.Rooms.RoomCase do
  @moduledoc """
  This module defines the setup and helper functions for tests requiring
  access to the application's messages model.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use DjRumble.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import DjRumble.Support.Rooms.RoomCase
    end
  end

  import DjRumble.AccountsFixtures
  import DjRumble.CollectionsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Rooms
  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor, RoomSupervisor}

  def create_user_room_videos do
    %{room: room} =
      room_videos_fixture(
        %{room: room_fixture(), videos: videos_fixture()},
        %{preload: true}
      )

    user = user_fixture()

    :ok =
      Enum.each(room.videos, fn video ->
        user_room_video = %{user: user, room: room, video: video}
        user_room_video_fixture(user_room_video)
      end)

    room = Rooms.preload_room(room, [:videos, users_rooms_videos: [:video, :user]])

    %{room: room, user: user}
  end

  def create_user_room_videos(amount) do
    for _n <- 1..amount do
      create_user_room_videos()
    end
  end

  def start_room_server do
    %{room: room, user: user} = create_user_room_videos()

    {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room)

    %{room: room, user: user, pid: pid}
  end

  def start_room_servers(amount) do
    for _n <- 1..amount do
      start_room_server()
    end
  end

  def fetch_matchmaking_rooms do
    matchmaking_servers =
      MatchmakingSupervisor.list_matchmaking_servers(MatchmakingSupervisor)
      |> Enum.map(&Matchmaking.get_state(&1))

    rooms =
      Enum.reduce(matchmaking_servers, [], fn matchmaking_server, acc ->
        videos =
          Enum.map(matchmaking_server.room.users_rooms_videos, fn user_room_video ->
            user_room_video.video
          end)

        acc ++ [{%{video: nil, added_by: nil}, matchmaking_server.room, videos}]
      end)

    %{rooms: rooms}
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
