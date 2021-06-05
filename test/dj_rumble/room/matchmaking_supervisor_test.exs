defmodule DjRumble.Room.MatchmakingSupervisorTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  # The MatchmakingSupervisor pid is automatically started on tests run since it's part
  # of the djrumble main application process.
  describe "matchmaking_supervisor" do
    alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor}

    setup do
      room = room_fixture()
      {:ok, pid} = MatchmakingSupervisor.start_matchmaking_server(MatchmakingSupervisor, room)

      on_exit(fn ->
        MatchmakingSupervisor.terminate_matchmaking_server(MatchmakingSupervisor, pid)
      end)

      initial_state = Matchmaking.initial_state(%{room: room})

      %{pid: pid, room: room, state: initial_state}
    end

    test "start_matchmaking_server/2 starts a matchmaking server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "list_matchmaking_servers/1 returns a list of matchmaking server pids", %{pid: pid} do
      assert Enum.member?(MatchmakingSupervisor.list_matchmaking_servers(), pid)
    end

    test "get_matchmaking_server/2 returns a matchmaking server pid and state", %{
      pid: pid,
      room: room,
      state: state
    } do
      {^pid, ^state} =
        MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, room.slug)

      assert Process.alive?(pid)
    end

    test "terminate_matchmaking_server/2 shuts down a matchmaking server process", %{pid: pid} do
      assert Process.alive?(pid)
      :ok = MatchmakingSupervisor.terminate_matchmaking_server(MatchmakingSupervisor, pid)
      refute Process.alive?(pid)
    end
  end
end
