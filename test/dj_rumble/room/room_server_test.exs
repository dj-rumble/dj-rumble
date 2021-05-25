defmodule DjRumble.Room.RoomServerTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  describe "room_server" do
    alias DjRumble.Rooms.RoomServer

    setup do
      room = room_fixture(%{}, %{preload: true})
      room_genserver_pid = start_supervised!({RoomServer, {room}})
      %{room: room, pid: room_genserver_pid}
    end

    test "start_link/1 starts a room server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "get_room/1 returns a room", %{pid: pid, room: room} do
      assert RoomServer.get_room(pid) == room
    end

    test "join/1 returns :ok", %{pid: pid} do
      assert RoomServer.join(pid) == :ok
    end

    test "start_round/1 returns :ok", %{pid: pid} do
      assert RoomServer.start_round(pid) == :ok
    end
  end
end
