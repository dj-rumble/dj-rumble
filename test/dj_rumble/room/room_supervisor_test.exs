defmodule DjRumble.Room.RoomSupervisorTest do
  @moduledoc """
  Room Supervisor tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  # The RoomSupervisor pid is automatically started on tests run since it's part
  # of the djrumble main application process.
  describe "room_supervisor" do
    alias DjRumble.Rooms.RoomSupervisor

    setup do
      %{room: %{slug: slug} = room} =
        room_videos_fixture(
          %{room: room_fixture(), videos: videos_fixture(3)},
          %{preload: true}
        )

      # chat_supervisor_pid = start_supervised!({ChatSupervisor, {room}})

      {:ok, pid} = RoomSupervisor.start_room_server(RoomSupervisor, room)

      on_exit(fn -> RoomSupervisor.terminate_room_server(RoomSupervisor, pid) end)

      {^pid, state} = RoomSupervisor.get_room_server(RoomSupervisor, slug)

      %{pid: pid, room: room, state: state}
    end

    test "start_room_server/2 starts a room server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "list_room_servers/1 returns a list of room server pids", %{pid: pid} do
      assert Enum.member?(RoomSupervisor.list_room_servers(), pid)
    end

    test "get_room_server/2 returns a room server pid and state", %{
      pid: pid,
      room: room,
      state: state
    } do
      {^pid, ^state} = RoomSupervisor.get_room_server(RoomSupervisor, room.slug)
      assert Process.alive?(pid)
    end

    test "terminate_room_server/2 shuts down a room server process", %{pid: pid} do
      assert Process.alive?(pid)
      :ok = RoomSupervisor.terminate_room_server(RoomSupervisor, pid)
      refute Process.alive?(pid)
    end
  end
end
