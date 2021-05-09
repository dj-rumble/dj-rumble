defmodule DjRumble.RoomsServersTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  # The RoomSupervisor pid is automatically started on tests run since it's part
  # of the djrumble main application process.
  describe "room_supervisor" do
    alias DjRumble.Rooms.RoomSupervisor

    setup do
      room = room_fixture()
      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room.id)
      %{pid: pid, room: room}
    end

    test "start_room_server/2 starts a room server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "list_room_servers/1 returns a list of room server pids", %{pid: pid} do
      assert Enum.member?(RoomSupervisor.list_room_servers(), pid)
    end

    test "get_room_server/2 returns a room server pid and state", %{pid: pid, room: room} do
      {^pid, room_id} = RoomSupervisor.get_room_server(RoomSupervisor, room.id)
      assert room_id == room.id
    end

    test "terminate_room_server/2 shuts down a room server process", %{pid: pid} do
      :ok = RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
      refute Process.alive?(pid)
    end
  end

  describe "room_server" do
    alias DjRumble.Rooms.RoomServer

    setup do
      room = room_fixture()
      room_genserver_pid = start_supervised!({RoomServer, {room.id}})
      %{room: room, pid: room_genserver_pid}
    end

    test "start_link/1 starts a room server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "get_room/1 returns a room id", %{pid: pid, room: room} do
      assert RoomServer.get_room(pid) == room.id
    end

    test "get_narration/1 returns a room id", %{pid: pid, room: room} do
      assert RoomServer.get_narration(pid) == room.id
    end

    test "start_round/1 returns :ok", %{pid: pid} do
      assert RoomServer.start_round(pid) == :ok
    end
  end
end
