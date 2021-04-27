defmodule DjRumbleWeb.RoomLiveTest do
  use DjRumbleWeb.ConnCase

  import DjRumble.RoomsFixtures
  import Phoenix.LiveViewTest

  # @create_attrs %{name: "some name", slug: "some slug"}
  # @update_attrs %{name: "some updated name", slug: "some updated slug"}
  # @invalid_attrs %{name: nil, slug: nil}

  describe "Index" do
    setup do
      rooms = rooms_fixture(10)
      %{rooms: rooms}
    end

    test "lists all rooms", %{conn: conn, rooms: rooms} do
      {:ok, _index_live, html} = live(conn, Routes.room_index_path(conn, :index))

      assert html =~ "Dj Rooms"
      for room <- rooms do
        assert html =~ room.name
      end
    end

    # @tag wip: true
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

    # test "deletes room in listing", %{conn: conn, room: room} do
    #   {:ok, index_live, _html} = live(conn, Routes.room_index_path(conn, :index))

    #   assert index_live |> element("#room-#{room.id} a", "Delete") |> render_click()
    #   refute has_element?(index_live, "#room-#{room.id}")
    # end
  end

  describe "Show" do

    test "displays room with no videos", %{conn: conn} do
      room = room_fixture()
      {:ok, show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))
      assert page_title(show_live) == nil
    end

    test "displays room with a video", %{conn: conn} do
      %{room: room} = room_videos_fixture(
        %{room: room_fixture(), videos: videos_fixture()}, %{preload: true})
      {:ok, _show_live, html} = live(conn, Routes.room_show_path(conn, :show, room.slug))
      assert html =~ Enum.at(room.videos, 0).title
    end

    # test "updates room within modal", %{conn: conn, room: room} do
    #   {:ok, _show_live, _html} = live(conn, Routes.room_show_path(conn, :show, room.slug))

    #   # assert show_live |> element("a", "Edit") |> render_click() =~
    #   #          "Edit Room"

    #   # assert_patch(show_live, Routes.room_show_path(conn, :edit, room))

    #   # assert show_live
    #   #        |> form("#room-form", room: @invalid_attrs)
    #   #        |> render_change() =~ "can&#39;t be blank"

    #   # {:ok, _, html} =
    #   #   show_live
    #   #   |> form("#room-form", room: @update_attrs)
    #   #   |> render_submit()
    #   #   |> follow_redirect(conn, Routes.room_show_path(conn, :show, room))

    #   # assert html =~ "Room updated successfully"
    #   # assert html =~ "some updated name"
    # end
  end
end
