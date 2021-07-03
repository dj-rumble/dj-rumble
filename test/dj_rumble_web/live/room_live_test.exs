defmodule DjRumbleWeb.RoomLiveTest do
  @moduledoc false

  use DjRumble.Support.Rooms.RoomCase
  use DjRumbleWeb.ConnCase

  import DjRumble.RoomsFixtures
  import Phoenix.LiveViewTest

  alias DjRumble.Rooms.RoomSupervisor

  # @create_attrs %{name: "some name", slug: "some slug"}
  # @update_attrs %{name: "some updated name", slug: "some updated slug"}
  # @invalid_attrs %{name: nil, slug: nil}

  describe "Index" do
    setup do
      servers_amount = 5
      room_servers = start_room_servers(servers_amount)

      %{rooms: rooms} = fetch_matchmaking_rooms()

      # Teardown
      on_exit(fn ->
        Enum.each(room_servers, fn %{pid: pid} ->
          RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
        end)
      end)

      %{rooms: rooms}
    end

    test "lists all rooms", %{conn: conn, rooms: rooms} do
      {:ok, _index_live, html} = live(conn, Routes.room_index_path(conn, :index))

      assert html =~ "Dj Rooms"

      for {_current_round, room, _videos} <- rooms do
        assert html =~ room.name
      end
    end

    # test "saves new room", %{conn: conn} do
    #   {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

    #   assert index_live |> element("a", "New Room") |> render_click() =~
    #            "New Room"

    #   assert_patch(index_live, Routes.room_index_path(conn, :new))

    #   assert index_live
    #          |> form("#room-form", room: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   {:ok, _, html} =
    #     index_live
    #     |> form("#room-form", room: @create_attrs)
    #     |> render_submit()
    #     |> follow_redirect(conn, Routes.room_index_path(conn, :index))

    #   assert html =~ "Room created successfully"
    #   assert html =~ "some name"
    # end
  end

  describe "Show" do
    defp start_room_server(room) do
      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room)

      # Teardown
      on_exit(fn ->
        RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
      end)

      :ok
    end

    test "displays room with no videos", %{conn: conn} do
      room = room_fixture(%{}, %{preload: true})
      :ok = start_room_server(room)
      {:ok, show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))
      assert page_title(show_live) == nil
    end

    test "displays room with a video", %{conn: conn} do
      %{room: room} =
        room_videos_fixture(
          %{room: room_fixture(), videos: videos_fixture()},
          %{preload: true}
        )

      :ok = start_room_server(room)
      {:ok, _show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))
      # assert html =~ Enum.at(room.videos, 0).title
    end
  end
end
