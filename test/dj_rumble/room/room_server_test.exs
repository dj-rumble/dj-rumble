defmodule DjRumble.Room.RoomServerTest do
  @moduledoc """
  Rooms context tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor, RoomServer, Video}
  alias DjRumble.Rounds.Round

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

      on_exit(fn ->
        :ok =
          MatchmakingSupervisor.terminate_matchmaking_server(
            MatchmakingSupervisor,
            matchmaking_server_pid
          )
      end)

      initial_state =
        RoomServer.initial_state(%{
          matchmaking_server: matchmaking_server_pid,
          room: room
        })

      %{
        matchmaking_server: matchmaking_server_pid,
        pid: room_genserver_pid,
        room: room,
        state: initial_state
      }
    end

    defp placeholder_video do
      Video.video_placeholder(%{title: "Waiting for the next round"})
    end

    defp get_video(round) do
      elem(elem(round, 1), 1)
    end

    defp is_pid_alive(pid) do
      is_pid(pid) and Process.alive?(pid)
    end

    defp prepare_next_round(matchmaking_server) do
      Process.send(matchmaking_server, :prepare_next_round, [])
    end

    defp receive_video_time(matchmaking_server, time) do
      Process.send(matchmaking_server, {:receive_video_time, time}, [])
    end

    defp start_next_round(matchmaking_server) do
      Process.send(matchmaking_server, :start_next_round, [])
    end

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

    test "list_next_rounds/1 returns a list of rounds and videos", %{
      matchmaking_server: matchmaking_server,
      state: state
    } do
      next_rounds = RoomServer.list_next_rounds(matchmaking_server)

      assert length(next_rounds) == length(state.room.videos)

      :ok =
        Enum.zip(next_rounds, state.room.videos)
        |> Enum.each(fn {%{round: round, video: round_video}, video} ->
          %Round.Scheduled{
            elapsed_time: 0,
            score: {0, 0},
            time: 0
          } = round

          assert round_video == video
        end)
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there are no next rounds",
         %{
           matchmaking_server: matchmaking_server
         } do
      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there is a next round",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [video | _videos] = state.room.videos
      :ok = RoomServer.create_round(matchmaking_server, video)
      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there are some next rounds",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      %{videos: videos} = state.room
      :ok = Enum.each(videos, &assert(RoomServer.create_round(matchmaking_server, &1) == :ok))

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video} = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a scheduled round with a video when there is a current round",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [video | _videos] = state.room.videos
      :ok = RoomServer.create_round(matchmaking_server, video)
      :ok = prepare_next_round(matchmaking_server)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        },
        video: ^video
      } = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a scheduled round with a video when there are some current rounds",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [video | _videos] = videos = state.room.videos
      :ok = Enum.each(videos, &assert(RoomServer.create_round(matchmaking_server, &1) == :ok))
      :ok = prepare_next_round(matchmaking_server)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        },
        video: ^video
      } = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a round that is in progress with a video when there is a next round",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [video | _videos] = state.room.videos
      :ok = RoomServer.create_round(matchmaking_server, video)
      :ok = prepare_next_round(matchmaking_server)
      time = 30
      :ok = receive_video_time(matchmaking_server, time)
      :ok = start_next_round(matchmaking_server)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        },
        video: ^video
      } = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a round that is in progress with a video when there are some next rounds",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [video | _videos] = videos = state.room.videos
      :ok = Enum.each(videos, &assert(RoomServer.create_round(matchmaking_server, &1) == :ok))
      :ok = prepare_next_round(matchmaking_server)
      time = 30
      :ok = receive_video_time(matchmaking_server, time)
      :ok = start_next_round(matchmaking_server)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        },
        video: ^video
      } = current_round
    end

    test "create_round/1 returns :ok and a round is scheduled", %{
      matchmaking_server: matchmaking_server,
      state: state
    } do
      # Setup
      [video | _videos] = state.room.videos

      # Exercise
      :ok = RoomServer.create_round(matchmaking_server, video)
    end
  end

  describe "room_server server implementation" do
    alias DjRumble.Rooms.Matchmaking
    alias DjRumbleWeb.Channels

    setup do
      room = room_fixture(%{}, %{preload: true})

      {:ok, matchmaking_server} =
        MatchmakingSupervisor.start_matchmaking_server(MatchmakingSupervisor, room)

      initial_state =
        RoomServer.initial_state(%{
          matchmaking_server: matchmaking_server,
          room: room
        })

      on_exit(fn ->
        MatchmakingSupervisor.terminate_matchmaking_server(
          MatchmakingSupervisor,
          matchmaking_server
        )
      end)

      %{state: initial_state}
    end

    defp handle_get_state(state) do
      response = RoomServer.handle_call(:get_state, nil, state)

      {:reply, state, new_state} = response

      assert state == new_state

      state
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

    defp handle_player_exits(state, ref) do
      response = RoomServer.handle_info({:DOWN, ref, :process, nil, nil}, state)

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

    defp do_players_exit(refs, state) do
      Enum.reduce(refs, {[], state}, fn ref, {refs, state} ->
        {refs ++ [ref], handle_player_exits(state, ref)}
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

    test "handle_call/3 :: :get_state replies with a state", %{state: state} do
      # Exercise
      response = RoomServer.handle_call(:get_state, nil, state)

      # Verify
      assert {:reply, ^state, ^state} = response
    end

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
      assert_receive({:trace, ^pid, :receive, {:welcome, "Hello!"}})

      assert_receive({:trace, ^matchmaking_server, :receive, :prepare_next_round})

      # Teardown
      on_exit(fn ->
        Process.exit(pid, :kill)
      end)
    end

    test "handle_call/3 :: {:joined, pid} is called some times, no rounds are started and some players receive playback details",
         %{
           state: state
         } do
      # Setup
      %{matchmaking_server: matchmaking_server, room: %{slug: slug}} = state

      :ok = Channels.subscribe(:player_is_ready, state.room.slug)

      :erlang.trace(matchmaking_server, true, [:receive])

      {pids, state} =
        spawn_players(3)
        # Exercise
        |> do_joined_players(state)

      # Verify
      :ok = assert_players_joined(pids, state)
      :ok = assert_players_received_a_welcome_message(pids)

      assert_receive({:trace, ^matchmaking_server, :receive, :prepare_next_round})

      assert_receive(:no_more_rounds)

      {^matchmaking_server, %{current_round: current_round}} =
        MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, slug)

      assert current_round == nil

      :ok =
        tl(pids)
        |> Enum.each(fn pid ->
          assert_receive({:trace, ^matchmaking_server, :receive, {_, _, {:join, ^pid}}})
        end)

      # Teardown
      on_exit(fn ->
        :ok = Enum.each(pids, &Process.exit(&1, :kill))
      end)
    end

    test "handle_call/3 :: {:joined, pid} is called some times, a round is started and some players receive playback details",
         %{
           state: state
         } do
      # Setup
      %{matchmaking_server: matchmaking_server, room: %{slug: slug}} = state

      :ok = Channels.subscribe(:player_is_ready, state.room.slug)

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
          assert_receive({:trace, ^matchmaking_server, :receive, {_, _, {:join, ^pid}}})
        end)

      # Teardown
      on_exit(fn ->
        :ok = Enum.each(pids, &Process.exit(&1, :kill))
      end)
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, reason} is called one time and returns a state without players",
         %{state: state} do
      # Setup
      state = handle_get_state(state)
      assert state.players == Map.new()

      {pids, state} =
        spawn_players(1)
        |> do_join_players(state)

      :ok = assert_players_joined(pids, state)

      refs = Map.keys(state.players)

      # Exercise
      {refs, state} = do_players_exit(refs, state)

      # Verify
      assert state.players == %{}
      :ok = Enum.each(refs, &refute(Map.has_key?(state.players, &1)))
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, reason} is called many times and returns a state without players",
         %{state: state} do
      # Setup
      state = handle_get_state(state)
      assert state.players == Map.new()

      {pids, state} =
        spawn_players(10)
        |> do_join_players(state)

      :ok = assert_players_joined(pids, state)

      refs = Map.keys(state.players)

      # Exercise
      {refs, state} = do_players_exit(refs, state)

      # Verify
      assert state.players == %{}
      :ok = Enum.each(refs, &refute(Map.has_key?(state.players, &1)))
    end
  end
end