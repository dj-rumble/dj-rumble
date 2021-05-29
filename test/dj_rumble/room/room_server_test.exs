defmodule DjRumble.Room.RoomServerTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  alias DjRumble.Rooms.{MatchmakingSupervisor, RoomServer}

  describe "room_server client interface" do
    setup do
      %{room: %{slug: slug, videos: videos} = room} =
        room_videos_fixture(
          %{room: room_fixture(), videos: videos_fixture(3)},
          %{preload: true}
        )

      room_genserver_pid = start_supervised!({RoomServer, {room}})

      {matchmaking_server_pid, state} =
        MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, slug)

      :ok =
        Enum.map(state.next_rounds, &get_video(&1))
        |> Enum.each(&Enum.member?(videos, &1))

      initial_state = %{
        matchmaking_server: matchmaking_server_pid,
        players: %{},
        room: room,
        current_video: nil,
        previous_videos: [],
        next_videos: room.videos
      }

      %{
        matchmaking_server: matchmaking_server_pid,
        pid: room_genserver_pid,
        room: room,
        state: initial_state
      }
    end

    defp get_video(round) do
      elem(elem(round, 1), 1)
    end

    defp is_pid_alive(pid) do
      is_pid(pid) and Process.alive?(pid)
    end

    @tag wip: true
    test "start_link/1 starts a room server", %{pid: pid} do
      assert is_pid_alive(pid)
    end

    test "start_link/1 starts a dedicated matchmaking server", %{
      matchmaking_server: matchmaking_server
    } do
      assert is_pid_alive(matchmaking_server)
    end

    test "get_state/1 returns a state", %{pid: pid, state: state} do
      assert RoomServer.get_state(pid) == state
    end

    test "join/1 returns :ok", %{pid: pid} do
      assert RoomServer.join(pid) == :ok
    end
  end

  describe "room_server server implementation" do
    alias DjRumble.Rooms.Matchmaking

    setup do
      %{videos: videos} = room = room_fixture(%{}, %{preload: true})

      {:ok, matchmaking_server} =
        MatchmakingSupervisor.start_matchmaking_server(MatchmakingSupervisor, room)

      initial_state = %{
        matchmaking_server: matchmaking_server,
        players: %{},
        room: room,
        current_video: nil,
        previous_videos: [],
        next_videos: videos
      }

      on_exit(fn ->
        MatchmakingSupervisor.terminate_matchmaking_server(
          MatchmakingSupervisor,
          matchmaking_server
        )
      end)

      %{state: initial_state}
    end

    defp handle_join(state, pid) do
      response = RoomServer.handle_call(:join, {pid, nil}, state)

      {:reply, :ok, state, {:continue, {:joined, ^pid}}} = response

      state
    end

    defp handle_joined(state, pid) do
      response = RoomServer.handle_continue({:joined, pid}, state)

      {:noreply, state} = response

      state
    end

    defp player_process_mock do
      receive do
        _ -> nil
      after
        5000 -> :timeout
      end

      player_process_mock()
    end

    defp spawn_players(n) do
      Enum.map(1..n, fn _ ->
        pid = spawn(fn -> player_process_mock() end)
        # Enables messages tracing going through pid
        :erlang.trace(pid, true, [:receive])
        assert is_pid_alive(pid)
        pid
      end)
    end

    defp do_join_players(pids, state) do
      Enum.reduce(pids, {[], state}, fn pid, {pids, state} ->
        {[pid | pids], handle_join(state, pid)}
      end)
    end

    defp do_joined_players(pids, state) do
      Enum.reduce(pids, {[], state}, fn pid, {pids, state} ->
        state = handle_join(state, pid)
        {pids ++ [pid], handle_joined(state, pid)}
      end)
    end

    defp get_player_pid(player) do
      elem(elem(player, 1), 0)
    end

    defp assert_players_joined(pids, state) do
      :ok =
        Enum.each(pids, fn pid ->
          assert Map.to_list(state.players)
                 |> Enum.map(&get_player_pid(&1))
                 |> Enum.member?(pid)
        end)
    end

    defp assert_players_received_a_welcome_message(pids) do
      :ok = Enum.each(pids, &assert_receive({:trace, ^&1, :receive, {:welcome, "Hello!"}}))
    end

    @tag wip: true
    test "handle_call/3 :: :get_state replies with a state", %{state: state} do
      # Exercise
      response = RoomServer.handle_call(:get_state, nil, state)

      # Verify
      assert {:reply, ^state, ^state} = response
    end

    @tag wip: true
    test "handle_call/3 :: :join is called with no players and replies with a state with a player",
         %{state: state} do
      # Setup
      pid = spawn(fn -> player_process_mock() end)
      assert is_pid_alive(pid)

      # Exercise
      state = handle_join(state, pid)

      # Verify
      assert Enum.any?(Map.to_list(state.players), &(get_player_pid(&1) == pid))

      # Teardown
      on_exit(fn ->
        Process.exit(pid, :kill)
      end)
    end

    @tag wip: true
    test "handle_call/3 :: :join is called some times and players are added in the state", %{
      state: state
    } do
      # Setup
      {pids, state} =
        spawn_players(3)
        # Exercise
        |> do_join_players(state)

      # Verify
      :ok = assert_players_joined(pids, state)

      # Teardown
      on_exit(fn ->
        :ok = Enum.each(pids, &Process.exit(&1, :kill))
      end)
    end

    @tag wip: true
    test "handle_call/3 :: {:joined, pid} is called with a player and a round is started", %{
      state: state
    } do
      # Setup
      %{matchmaking_server: matchmaking_server} = state
      :erlang.trace(matchmaking_server, true, [:receive])

      pid = spawn(fn -> player_process_mock() end)
      :erlang.trace(pid, true, [:receive])
      assert is_pid_alive(pid)
      state = handle_join(state, pid)
      assert Enum.any?(Map.to_list(state.players), &(get_player_pid(&1) == pid))

      # Exercise
      _state = handle_joined(state, pid)

      # Verify
      self = self()
      assert_received({:trace, ^pid, :receive, {:welcome, "Hello!"}})

      assert_received {:trace, ^matchmaking_server, :receive,
                       {_, {^self, _}, :prepare_initial_round}}

      # Teardown
      on_exit(fn ->
        Process.exit(pid, :kill)
      end)
    end

    @tag wip: true
    test "handle_call/3 :: {:joined, pid} is called some times, no rounds are started and some players receive playback details",
         %{
           state: state
         } do
      # Setup
      %{matchmaking_server: matchmaking_server, room: %{slug: slug}} = state

      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{slug}:ready")

      self = self()
      :erlang.trace(matchmaking_server, true, [:receive])

      {pids, state} =
        spawn_players(3)
        # Exercise
        |> do_joined_players(state)

      # Verify
      :ok = assert_players_joined(pids, state)
      :ok = assert_players_received_a_welcome_message(pids)

      assert_receive(
        {:trace, ^matchmaking_server, :receive, {_, {^self, _}, :prepare_initial_round}}
      )

      assert_receive(:no_more_rounds)

      {^matchmaking_server, %{current_round: current_round}} =
        MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, slug)

      assert current_round == nil

      :ok =
        tl(pids)
        |> Enum.each(fn pid ->
          assert_receive({:trace, ^matchmaking_server, :receive, {_, {:join, ^pid}}})
        end)

      # Teardown
      on_exit(fn ->
        :ok = Enum.each(pids, &Process.exit(&1, :kill))
      end)
    end

    @tag wip: true
    test "handle_call/3 :: {:joined, pid} is called some times, a round is started and some players receive playback details",
         %{
           state: state
         } do
      # Setup
      %{matchmaking_server: matchmaking_server, room: %{slug: slug}} = state

      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{slug}:ready")

      %{video_id: video_id} = video = video_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video)
      :erlang.trace(matchmaking_server, true, [:receive])

      {pids, state} =
        spawn_players(3)
        # Exercise
        |> do_joined_players(state)

      # Verify
      :ok = assert_players_joined(pids, state)
      :ok = assert_players_received_a_welcome_message(pids)
      assert_receive({:request_playback_details, %{time: 0, videoId: ^video_id}})

      {^matchmaking_server, %{current_round: current_round}} =
        MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, slug)

      assert current_round != nil
      assert get_video(current_round) == video

      :ok =
        tl(pids)
        |> Enum.each(fn pid ->
          assert_receive({:trace, ^matchmaking_server, :receive, {_, {:join, ^pid}}})
        end)

      # Teardown
      on_exit(fn ->
        :ok = Enum.each(pids, &Process.exit(&1, :kill))
      end)
    end

    # @tag wip: true
    # test "handle_info/2 :: {:DOWN, ref, :process, pid, reason} is called many times and returns a state without players", %{state: state} do
    #   {pids, state} = spawn_players(3)
    #   # Setup
    #   |> do_join_players(state)

    #   :ok = assert_players_joined(pids, state)

    #   {pids, state} = RoomServer.handle_info({:DOWN, })

    #   {_, state} =
    # end
  end
end
