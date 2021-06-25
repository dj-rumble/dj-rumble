defmodule DjRumble.Room.RoomServerTest do
  @moduledoc """
  Room Server tests
  """
  use DjRumble.DataCase
  use DjRumble.TestCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.CollectionsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Chats.{ChatServer, ChatSupervisor}
  alias DjRumble.Rooms
  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor, RoomServer, Video}
  alias DjRumble.Rounds.Round

  alias DjRumbleWeb.Channels

  defp generate_score(:mixed, users) do
    types = [:positive, :negative]

    Enum.map(users, fn user ->
      {user, Enum.at(types, Enum.random(0..(length(types) - 1)))}
    end)
  end

  defp generate_score(type, users) do
    Enum.map(users, fn user -> {user, type} end)
  end

  defp generate_message(user, message) do
    {user, message}
  end

  defp generate_messages(user, message, n) do
    for _n <- 1..n, do: generate_message(user, message)
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

  describe "room_server client interface" do
    setup do
      room = room_fixture()
      videos = videos_fixture(3)
      user = user_fixture()

      :ok =
        Enum.each(videos, fn video ->
          user_room_video = %{user: user, room: room, video: video}
          user_room_video_fixture(user_room_video)
        end)

      room = Rooms.preload_room(room, users_rooms_videos: [:video, :user])

      %{slug: slug} = room

      chat_topic = Channels.get_topic(:room_chat, slug)
      chat_server_pid = start_supervised!({ChatServer, {chat_topic}})

      room_genserver_pid = start_supervised!({RoomServer, {room, chat_server_pid}})

      {matchmaking_server_pid, matchmaking_state} =
        MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, slug)

      :ok =
        Enum.map(matchmaking_state.next_rounds, &get_video(&1))
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
          chat_server: chat_server_pid,
          room: room
        })

      %{
        chat_server: chat_server_pid,
        matchmaking_server: matchmaking_server_pid,
        pid: room_genserver_pid,
        room: room,
        state: initial_state,
        user: user
      }
    end

    defp placeholder_video do
      Video.video_placeholder(%{title: "Waiting for the next round"})
    end

    defp get_video(round) do
      elem(elem(round, 1), 1)
    end

    def get_videos_users(room) do
      Enum.map(room.users_rooms_videos, fn user_room_video ->
        {user_room_video.video, user_room_video.user}
      end)
    end

    defp create_round(matchmaking_server, video, user) do
      RoomServer.create_round(matchmaking_server, video, user)
    end

    defp create_rounds(matchmaking_server, videos_users) do
      Enum.each(videos_users, fn {video, user} ->
        assert(create_round(matchmaking_server, video, user) == :ok)
      end)
    end

    defp do_score(server, {user, score}) do
      :ok = RoomServer.score(server, user, score)
    end

    defp do_scores(server, users_scores) do
      Enum.each(users_scores, &do_score(server, &1))
    end

    defp schedule_and_start_round(matchmaking_server, videos_users, time) do
      :ok = create_rounds(matchmaking_server, videos_users)
      :ok = prepare_next_round(matchmaking_server)
      :ok = receive_video_time(matchmaking_server, time)
      :ok = start_next_round(matchmaking_server)
    end

    defp do_new_message(pid, user, message) do
      :ok = RoomServer.new_message(pid, user, message)
    end

    defp do_new_messages(pid, users_messages) do
      for {user, message} <- users_messages do
        :ok = do_new_message(pid, user, message)
      end
    end

    test "start_link/1 starts a room server", %{pid: pid} do
      assert is_pid_alive(pid)
    end

    test "start_link/1 starts a dedicated matchmaking server", %{
      matchmaking_server: matchmaking_server
    } do
      assert is_pid_alive(matchmaking_server)
    end

    test "start_link/1 starts a dedicated chat server", %{
      chat_server: chat_server
    } do
      assert is_pid_alive(chat_server)
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
      videos_users = get_videos_users(state.room)

      next_rounds = RoomServer.list_next_rounds(matchmaking_server)

      assert length(next_rounds) == length(videos_users)

      :ok =
        Enum.zip(next_rounds, videos_users)
        |> Enum.each(fn {%{round: round, video: round_video, user: round_user}, {video, user}} ->
          %Round.Scheduled{
            elapsed_time: 0,
            score: {0, 0},
            time: 0
          } = round

          assert round_video == video
          assert round_user == user
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
      [{video, user} | _videos_users] = get_videos_users(state.room)
      :ok = create_rounds(matchmaking_server, [{video, user}])
      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video, user: nil} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there are some next rounds",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [{_video, _user} | _videos_users] = videos_users = get_videos_users(state.room)

      :ok = create_rounds(matchmaking_server, videos_users)
      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video, user: nil} = current_round
    end

    test "get_current_round/1 returns a scheduled round with a video when there is a current round",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [{video, user} | _videos_users] = videos_users = get_videos_users(state.room)
      :ok = create_rounds(matchmaking_server, videos_users)
      :ok = prepare_next_round(matchmaking_server)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        },
        video: ^video,
        user: ^user
      } = current_round
    end

    test "get_current_round/1 returns a scheduled round with a video when there are some current rounds",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [{video, user} | _videos_users] = videos_users = get_videos_users(state.room)
      :ok = create_rounds(matchmaking_server, videos_users)
      :ok = prepare_next_round(matchmaking_server)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        },
        video: ^video,
        user: ^user
      } = current_round
    end

    test "get_current_round/1 returns a round that is in progress with a video when there is a next round",
         %{
           matchmaking_server: matchmaking_server,
           state: state
         } do
      # Setup
      [{video, user} | _videos_users] = videos_users = get_videos_users(state.room)
      time = 30
      :ok = schedule_and_start_round(matchmaking_server, videos_users, time)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        },
        video: ^video,
        user: ^user
      } = current_round
    end

    test "get_current_round/1 returns a round that is in progress with a video when there are some next rounds",
         %{
           matchmaking_server: matchmaking_server,
           state: state,
           user: user
         } do
      # Setup
      [{video, _user} | _videos_users] = videos_users = get_videos_users(state.room)
      time = 30
      :ok = schedule_and_start_round(matchmaking_server, videos_users, time)

      # Exercise
      current_round = RoomServer.get_current_round(matchmaking_server)

      # Verify
      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        },
        video: ^video,
        user: ^user
      } = current_round
    end

    test "create_round/3 returns :ok and a round is scheduled", %{
      matchmaking_server: matchmaking_server,
      state: state
    } do
      # Setup
      [{video, user} | _videos_users] = get_videos_users(state.room)

      # Exercise
      :ok = create_round(matchmaking_server, video, user)
    end

    test "score/2 is called once and returns :ok", %{
      matchmaking_server: matchmaking_server,
      pid: pid,
      state: state
    } do
      # Setup
      videos_users = get_videos_users(state.room)
      time = 30
      :ok = schedule_and_start_round(matchmaking_server, videos_users, time)
      [{_pid, user}] = spawn_players(1)
      users_scores = generate_score(:positive, [user])

      # Exercise
      :ok = do_scores(pid, users_scores)
    end

    test "score/2 is called many times and returns :ok", %{
      matchmaking_server: matchmaking_server,
      pid: pid,
      state: state
    } do
      # Setup
      videos_users = get_videos_users(state.room)
      time = 30
      :ok = schedule_and_start_round(matchmaking_server, videos_users, time)
      players = spawn_players(5)
      users = Enum.map(players, fn {_pid, user} -> user end)
      users_scores = generate_score(:positive, users)

      # Exercise
      :ok = do_scores(pid, users_scores)
    end

    test "new_message/2 is called once and returns :ok", %{pid: pid} do
      # Setup
      user = user_fixture()
      message = "Hello!"

      # Exercise & Verify
      :ok = do_new_message(pid, user, message)
    end

    test "new_message/2 is called many times and returns :ok", %{pid: pid} do
      # Setup
      user = user_fixture()
      message = "Hello!"
      messages_amount = 10
      users_messages = generate_messages(user, message, messages_amount)

      # Exercise & Verify
      responses = do_new_messages(pid, users_messages)
      ^messages_amount = length(responses)
    end
  end

  describe "room_server server implementation" do
    alias DjRumble.Rooms.Matchmaking
    alias DjRumbleWeb.Channels

    setup do
      room = room_fixture(%{}, %{preload: true})

      {:ok, matchmaking_server} =
        MatchmakingSupervisor.start_matchmaking_server(MatchmakingSupervisor, room)

      {:ok, chat_server} = ChatSupervisor.start_server(ChatSupervisor, {room.slug})

      initial_state =
        RoomServer.initial_state(%{
          chat_server: chat_server,
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

    defp handle_score(state, {user, score}) do
      response = RoomServer.handle_call({:score, user, score}, nil, state)

      {:reply, :ok, ^state} = response

      state
    end

    defp handle_scores(state, users_scores) do
      Enum.reduce(users_scores, {[], state}, fn {user, score}, {users, acc_state} ->
        {users ++ [user], handle_score(acc_state, {user, score})}
      end)
    end

    defp handle_new_message(state, {user, message}) do
      response = RoomServer.handle_cast({:new_message, user, message}, state)

      {:noreply, ^state} = response

      state
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

    defp assert_players_receive_a_welcome_message(pids) do
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
      [{pid, _user}] = _players = spawn_players(1)
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
      players = spawn_players(3)
      pids = Enum.map(players, fn {pid, _user} -> pid end)

      # Exercise
      {pids, state} = do_join_players(pids, state)

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

      [{pid, _user}] = _players = spawn_players(1)
      :erlang.trace(pid, true, [:receive])
      assert is_pid_alive(pid)
      state = handle_join(state, pid)
      assert Enum.any?(Map.to_list(state.players), &(get_player_pid(&1) == pid))

      # Exercise
      _state = handle_joined(state, pid)

      # Verify
      :ok = assert_players_receive_a_welcome_message([pid])

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

      players = spawn_players(3)
      pids = Enum.map(players, fn {pid, _user} -> pid end)

      # Exercise
      {pids, state} = do_joined_players(pids, state)

      # Verify
      :ok = assert_players_joined(pids, state)
      :ok = assert_players_receive_a_welcome_message(pids)

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
      user = user_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video, user)
      :erlang.trace(matchmaking_server, true, [:receive])

      players = spawn_players(3)
      pids = Enum.map(players, fn {pid, _user} -> pid end)

      # Exercise
      {pids, state} = do_joined_players(pids, state)

      # Verify
      :ok = assert_players_joined(pids, state)
      :ok = assert_players_receive_a_welcome_message(pids)
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

    test "handle_call/3 :: {:score, %User{}, :positive} is called once time and returns :ok", %{
      state: state
    } do
      # Setup
      %{matchmaking_server: matchmaking_server} = state
      video = video_fixture()
      user = user_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video, user)
      :ok = prepare_next_round(matchmaking_server)
      :ok = receive_video_time(matchmaking_server, 30)
      :ok = start_next_round(matchmaking_server)

      players = spawn_players(1)
      pids = Enum.map(players, fn {pid, _user} -> pid end)
      users = Enum.map(players, fn {_pid, user} -> user end)

      {_pids, state} = do_join_players(pids, state)

      users_scores = generate_score(:positive, users)

      # Exercise
      _state = handle_scores(state, users_scores)
    end

    test "handle_call/3 :: {:score, %User{}, :positive} is called many times and returns :ok every time",
         %{state: state} do
      # Setup
      %{matchmaking_server: matchmaking_server} = state
      video = video_fixture()
      user = user_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video, user)
      :ok = prepare_next_round(matchmaking_server)
      :ok = receive_video_time(matchmaking_server, 30)
      :ok = start_next_round(matchmaking_server)

      players = spawn_players(10)

      pids = Enum.map(players, fn {pid, _user} -> pid end)
      users = Enum.map(players, fn {_pid, user} -> user end)

      {_pids, state} = do_join_players(pids, state)

      users_scores = generate_score(:positive, users)

      # Exercise
      _state = handle_scores(state, users_scores)
    end

    test "handle_call/3 :: {:score, %User{}, :negative} is called once time and returns :ok", %{
      state: state
    } do
      # Setup
      %{matchmaking_server: matchmaking_server} = state
      video = video_fixture()
      user = user_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video, user)
      :ok = prepare_next_round(matchmaking_server)
      :ok = receive_video_time(matchmaking_server, 30)
      :ok = start_next_round(matchmaking_server)

      players = spawn_players(1)
      pids = Enum.map(players, fn {pid, _user} -> pid end)
      users = Enum.map(players, fn {_pid, user} -> user end)

      {_pids, state} = do_join_players(pids, state)

      users_scores = generate_score(:negative, users)

      # Exercise
      _state = handle_scores(state, users_scores)
    end

    test "handle_call/3 :: {:score, %User{}, :negative} is called many times and returns :ok every time",
         %{state: state} do
      # Setup
      %{matchmaking_server: matchmaking_server} = state
      video = video_fixture()
      user = user_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video, user)
      :ok = prepare_next_round(matchmaking_server)
      :ok = receive_video_time(matchmaking_server, 30)
      :ok = start_next_round(matchmaking_server)

      players = spawn_players(10)
      pids = Enum.map(players, fn {pid, _user} -> pid end)
      users = Enum.map(players, fn {_pid, user} -> user end)

      {_pids, state} = do_join_players(pids, state)

      users_scores = generate_score(:negative, users)

      # Exercise
      _state = handle_scores(state, users_scores)
    end

    test "handle_call/3 :: {:score, %User{}, type} is called many times with mixed scores and returns :ok every time",
         %{state: state} do
      # Setup
      %{matchmaking_server: matchmaking_server} = state
      video = video_fixture()
      user = user_fixture()
      :ok = Matchmaking.create_round(matchmaking_server, video, user)
      :ok = prepare_next_round(matchmaking_server)
      :ok = receive_video_time(matchmaking_server, 30)
      :ok = start_next_round(matchmaking_server)

      players = spawn_players(10)
      pids = Enum.map(players, fn {pid, _user} -> pid end)
      users = Enum.map(players, fn {_pid, user} -> user end)

      {_pids, state} = do_join_players(pids, state)

      users_scores = generate_score(:mixed, users)

      # Exercise
      _state = handle_scores(state, users_scores)
    end

    test "handle_cast/2 :: {:new_message, %User{}, message} is called once and returns an unmodified state",
         %{state: state} do
      user = user_fixture()
      message = "Hello!"

      # Exercise & Verify
      ^state = handle_new_message(state, {user, message})
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, reason} is called one time and returns a state without players",
         %{state: state} do
      # Setup
      state = handle_get_state(state)
      assert state.players == Map.new()

      players = spawn_players(1)
      pids = Enum.map(players, fn {pid, _user} -> pid end)

      {pids, state} = do_join_players(pids, state)

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

      players = spawn_players(10)
      pids = Enum.map(players, fn {pid, _user} -> pid end)

      {pids, state} = do_join_players(pids, state)

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
