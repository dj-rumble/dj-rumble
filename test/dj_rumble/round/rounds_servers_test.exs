defmodule DjRumble.Round.RoundServerTest do
  @moduledoc """
  Rounds servers tests
  """
  alias GenServer
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  # The RoundSupervisor pid is automatically started on tests run since it's
  # part of the djrumble main application process.
  describe "round_supervisor" do
    alias DjRumble.Rounds.RoundSupervisor

    setup do
      room = room_fixture(%{}, %{preload: true})
      round_time = 5
      {:ok, pid} = RoundSupervisor.start_round_server(RoundSupervisor, {room.slug, round_time})

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

  describe "round_server" do
    alias DjRumble.Rounds.{Action, Log, Round}
    alias DjRumble.Rounds.RoundServer

    setup do
      room = room_fixture()
      round_time = 2
      round_genserver_pid = start_supervised!({RoundServer, {room.slug, round_time}})
      %{room: room, round_time: round_time, pid: round_genserver_pid}
    end

    test "start_link/1 starts a round server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "get_room_slug/1 returns a room slug", %{pid: pid, room: room} do
      assert RoundServer.get_room_slug(pid) == room.slug
    end

    test "start_round/1 returns :ok", %{pid: pid} do
      assert RoundServer.start_round(pid) == :ok
    end

    test "start_round/1 ticks until the round pid terminates", %{pid: pid} do
      :ok = RoundServer.start_round(pid)
      :ok = Process.sleep(2500)
      refute Process.alive?(pid)
    end

    test "get_round/1 returns a scheduled round", %{pid: pid, round_time: round_time} do
      %Round.Scheduled{time: ^round_time, elapsed_time: elapsed_time, score: score} =
        RoundServer.get_round(pid)

      assert elapsed_time == 0
      assert score == {0, 0}
    end

    test "get_round/1 returns a round that is in progress", %{pid: pid, round_time: round_time} do
      :ok = RoundServer.start_round(pid)

      %Round.InProgress{time: ^round_time, elapsed_time: elapsed_time, score: score, log: log} =
        RoundServer.get_round(pid)

      assert elapsed_time == 0
      assert score == {0, 0}
      assert log == Log.new()
    end

    test "get_narration/1 returns a log from a round that is in progress", %{pid: pid} do
      :ok = RoundServer.start_round(pid)
      assert RoundServer.get_narration(pid) == Round.narrate(Round.InProgress.new())
    end

    test "handle_info/2 :tick updates a round that is in progress", %{
      pid: pid,
      round_time: round_time
    } do
      :ok = RoundServer.start_round(pid)
      :ok = Process.send(pid, :tick, [])
      %Round.InProgress{time: ^round_time, elapsed_time: 1, log: log} = RoundServer.get_round(pid)
      assert log == Log.append(Log.new(), %Action.CountTime{})
    end
  end
end
