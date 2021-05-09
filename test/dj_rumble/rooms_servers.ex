defmodule DjRumble.RoomsServersTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  describe "room_supervisor" do
    alias DjRumble.Rooms.RoomSupervisor

    test "start_room_server/2 starts a room server" do
      room = room_fixture()
      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room.id)
      assert is_pid(pid)
    end

    test "list_room_servers/1 returns a list of room server pids" do
      room = room_fixture()
      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room.id)
      assert Enum.member?(RoomSupervisor.list_room_servers(), pid)
    end

    test "get_room_server/2 returns a room server pid and state" do
      room = room_fixture()
      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room.id)
      {^pid, room_id} = RoomSupervisor.get_room_server(RoomSupervisor, room.id)
      assert room_id == room.id
    end

    test "terminate_room_server/2 shuts down a room server process" do
      room = room_fixture()
      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room.id)
      :ok = RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
      assert Process.alive?(pid) == false
    end
  end
end
