defmodule DjRumble.Round.RoundSupervisorTest do
  @moduledoc """
  Round Supervisor tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  # The RoundSupervisor pid is automatically started on tests run since it's
  # part of the djrumble main application process.
  describe "round_supervisor" do
    alias DjRumble.Rounds.RoundSupervisor

    setup do
      room = room_fixture(%{}, %{preload: true})
      {:ok, pid} = RoundSupervisor.start_round_server(RoundSupervisor, {room.slug})

      on_exit(fn ->
        RoundSupervisor.terminate_round_server(RoundSupervisor, pid)
      end)

      %{pid: pid, room: room}
    end

    test "start_round_server/2 starts a round server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "list_round_servers/1 returns a list of round server pids", %{pid: pid} do
      assert Enum.member?(RoundSupervisor.list_round_servers(), pid)
    end

    test "get_round_server/2 returns a round server pid and state", %{pid: pid, room: room} do
      {^pid, room_slug} = RoundSupervisor.get_round_server(RoundSupervisor, room.slug)
      assert Process.alive?(pid)
      assert room_slug == room.slug
    end

    test "terminate_room_server/2 shuts down a round server process", %{pid: pid} do
      assert Process.alive?(pid)
      :ok = RoundSupervisor.terminate_round_server(RoundSupervisor, pid)
      refute Process.alive?(pid)
    end
  end
end
