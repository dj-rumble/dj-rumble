defmodule DjRumble.Room.MatchmakingTest do
  @moduledoc """
  Matchmaking tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Rooms.Video

  alias DjRumble.Rounds.Round

  # Helper functions

  defp generate_score(:mixed, users) do
    types = [:positive, :negative]

    Enum.map(users, fn user ->
      {user, Enum.at(types, Enum.random(0..(length(types) - 1)))}
    end)
  end

  defp generate_score(type, users) do
    Enum.map(users, fn user -> {user, type} end)
  end

  defp get_evaluated_score(scores, initial_score) do
    Enum.reduce(scores, initial_score, fn score, {p, n} ->
      case score do
        :positive -> {p + 1, n}
        :negative -> {p, n + 1}
      end
    end)
  end

  defp start_next_round(server) do
    Process.send(server, :start_next_round, [])
  end

  defp user_fixtures(n) do
    for _n <- 1..n, do: user_fixture()
  end

  describe "matchmaking client interface" do
    alias DjRumble.Rooms.Matchmaking

    setup do
      %{room: room} =
        room_videos_fixture(
          %{room: room_fixture(), videos: videos_fixture()},
          %{preload: true}
        )

      user = user_fixture()

      matchmaking_genserver_pid = start_supervised!({Matchmaking, {room}})

      initial_state = Matchmaking.initial_state(%{room: room})

      %{pid: matchmaking_genserver_pid, room: room, state: initial_state, user: user}
    end

    defp placeholder_video do
      Video.video_placeholder(%{title: "Waiting for the next round"})
    end

    defp prepare_next_round(server) do
      Process.send(server, :prepare_next_round, [])
    end

    defp receive_video_time(server, time) do
      Process.send(server, {:receive_video_time, time}, [])
    end

    defp create_round(pid, video, user) do
      Matchmaking.create_round(pid, video, user)
    end

    defp create_rounds(pid, videos_users) do
      Enum.each(videos_users, fn {video, user} ->
        assert(create_round(pid, video, user) == :ok)
      end)
    end

    defp get_current_round(pid) do
      Matchmaking.get_current_round(pid)
    end

    defp schedule_and_start_round(pid, videos_users, time) do
      :ok = create_rounds(pid, videos_users)
      :ok = prepare_next_round(pid)
      :ok = receive_video_time(pid, time)
      :ok = start_next_round(pid)
    end

    defp do_score(server, user, score) do
      Matchmaking.score(server, user, score)
    end

    defp do_scores(server, users_scores) do
      for {user, score} <- users_scores do
        do_score(server, user, score)
      end
      |> List.last()
    end

    test "start_link/1 starts a matchmaking server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "get_state/1 returns a state", %{pid: pid, state: state} do
      assert Matchmaking.get_state(pid) == state
    end

    test "create_round/3 returns :ok", %{pid: pid, room: room, user: user} do
      [video | _videos] = room.videos
      assert create_round(pid, video, user) == :ok
    end

    test "list_next_rounds/1 returns a list of rounds and videos", %{
      pid: pid,
      state: state,
      user: user
    } do
      # Setup
      %{room: %{videos: videos}} = state
      videos_users = Enum.map(videos, &{&1, user})
      :ok = create_rounds(pid, videos_users)

      # Exercise
      next_rounds = Matchmaking.list_next_rounds(pid)

      # Verify
      assert length(next_rounds) == length(videos)

      :ok =
        Enum.zip(next_rounds, videos)
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
         %{pid: pid} do
      # Exercise
      current_round = get_current_round(pid)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video, user: nil} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there is a next round",
         %{pid: pid, state: state, user: user} do
      # Setup
      [video | _videos] = state.room.videos
      assert create_round(pid, video, user) == :ok

      # Exercise
      current_round = get_current_round(pid)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video, user: nil} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there are some next rounds",
         %{pid: pid, state: state, user: user} do
      # Setup
      %{videos: videos} = state.room
      videos_users = Enum.map(videos, &{&1, user})
      :ok = create_rounds(pid, videos_users)

      # Exercise
      current_round = get_current_round(pid)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video, user: nil} = current_round
    end

    test "get_current_round/1 returns a scheduled round with a video when there is a current round",
         %{pid: pid, state: state, user: user} do
      # Setup
      [video | _videos] = state.room.videos

      :ok = create_round(pid, video, user)
      :ok = prepare_next_round(pid)

      # Exercise
      current_round = get_current_round(pid)

      # Verify
      %{video: ^video, user: ^user} = current_round

      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        }
      } = current_round
    end

    test "get_current_round/1 returns a scheduled round with a video when there are some current rounds",
         %{pid: pid, state: state, user: user} do
      # Setup
      %{videos: [video | _videos] = videos} = state.room
      videos_users = Enum.map(videos, &{&1, user})
      :ok = create_rounds(pid, videos_users)
      :ok = prepare_next_round(pid)

      # Exercise
      current_round = get_current_round(pid)

      # Verify
      %{video: ^video, user: ^user} = current_round

      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        }
      } = current_round
    end

    test "get_current_round/1 returns a round that is in progress with a video when there is a next round",
         %{pid: pid, state: state, user: user} do
      # Setup
      %{videos: [video | _videos] = videos} = state.room
      time = 30
      videos_users = Enum.map(videos, &{&1, user})
      :ok = schedule_and_start_round(pid, videos_users, time)

      # Exercise
      current_round = get_current_round(pid)

      # Verify
      %{video: ^video, user: ^user} = current_round

      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        }
      } = current_round
    end

    test "get_current_round/1 returns a round that is in progress with a video when there are some current rounds",
         %{pid: pid, state: state, user: user} do
      # Setup
      %{videos: [video | _videos] = videos} = state.room
      time = 30
      videos_users = Enum.map(videos, &{&1, user})
      :ok = schedule_and_start_round(pid, videos_users, time)

      # Exercise
      current_round = get_current_round(pid)

      # Verify
      %{video: ^video, user: ^user} = current_round

      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        }
      } = current_round
    end

    test "score/2 is called once and returns :ok", %{pid: pid, state: state, user: user} do
      # Setup
      time = 30
      %{videos: videos} = state.room
      videos_users = Enum.map(videos, &{&1, user})
      :ok = schedule_and_start_round(pid, videos_users, time)
      %{round: %Round.InProgress{score: initial_score}} = get_current_round(pid)

      users_scores = generate_score(:positive, [user])
      scores = Enum.map(users_scores, fn {_user, score} -> score end)

      {1, 0} = evaluated_score = get_evaluated_score(scores, initial_score)

      # Exercise
      round = do_scores(pid, users_scores)

      # Verify
      %Round.InProgress{score: ^evaluated_score} = round
    end

    test "score/2 is called many times and returns a round with an updated score", %{
      pid: pid,
      state: state,
      user: user
    } do
      # Setup
      %{videos: videos} = state.room
      time = 30
      videos_users = Enum.map(videos, &{&1, user})
      :ok = schedule_and_start_round(pid, videos_users, time)
      %{round: %Round.InProgress{score: initial_score}} = get_current_round(pid)

      users = user_fixtures(3)
      users_scores = generate_score(:positive, users)
      scores = Enum.map(users_scores, fn {_user, score} -> score end)

      {3, 0} = evaluated_score = get_evaluated_score(scores, initial_score)

      # Exercise
      round = do_scores(pid, users_scores)

      # Verify
      %Round.InProgress{score: ^evaluated_score} = round
    end

    test "score/2 is called many times with mixed scores and returns :ok", %{
      pid: pid,
      state: state,
      user: user
    } do
      # Setup
      %{videos: videos} = state.room
      time = 30
      videos_users = Enum.map(videos, &{&1, user})
      :ok = schedule_and_start_round(pid, videos_users, time)
      %{round: %Round.InProgress{score: initial_score}} = get_current_round(pid)

      users = user_fixtures(3)
      users_scores = generate_score(:mixed, users)
      scores = Enum.map(users_scores, fn {_user, score} -> score end)

      evaluated_score = get_evaluated_score(scores, initial_score)

      # Exercise
      round = do_scores(pid, users_scores)

      # Verify
      %Round.InProgress{score: ^evaluated_score} = round
    end
  end

  describe "matchmaking server implementation" do
    alias DjRumble.Rooms
    alias DjRumble.Rooms.Matchmaking
    alias DjRumble.Rounds.Round
    alias DjRumbleWeb.Channels

    import DjRumble.CollectionsFixtures

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

      state = Matchmaking.initial_state(%{room: room})

      %{room: room, state: state, user: user}
    end

    defp handle_schedule_round(state, video, user) do
      response = Matchmaking.handle_call({:schedule_round, {video, user}}, nil, state)

      assert {:reply, :ok, state} = response

      state
    end

    defp schedule_rounds(state, videos_users) do
      :ok = Channels.subscribe(:room, state.room.slug)

      Enum.reduce(Enum.with_index(videos_users), state, fn {{video, user}, index}, acc_state ->
        %{
          current_round: current_round,
          next_rounds: next_rounds
        } = state = handle_schedule_round(acc_state, video, user)

        assert current_round == nil
        assert length(next_rounds) == index + 1
        assert is_valid_round(:scheduled, Enum.at(next_rounds, index), %{video: video})
        assert_received({:round_scheduled, _scheduled_round})

        state
      end)
    end

    defp handle_prepare_next_round(state) do
      response = Matchmaking.handle_info(:prepare_next_round, state)

      assert {:noreply, state} = response

      state
    end

    defp handle_list_next_rounds(state) do
      response = Matchmaking.handle_call(:list_next_rounds, nil, state)

      {:reply, next_rounds, _state} = response

      next_rounds
    end

    defp handle_join(state, pid) do
      response = Matchmaking.handle_call({:join, pid}, nil, state)

      {:reply, :ok, state} = response

      state
    end

    defp handle_score(state, user, type) do
      response = Matchmaking.handle_call({:score, user, type}, nil, state)

      {:reply, %Round.InProgress{} = round, new_state} = response

      assert new_state == state

      {round, state}
    end

    defp handle_scores(state, users_scores) do
      Enum.reduce(users_scores, {[], nil, state}, fn {user, score},
                                                     {users_scores, _round, state} ->
        {round, state} = handle_score(state, user, score)
        {users_scores ++ [{user, score}], round, state}
      end)
    end

    defp handle_receive_video_time(state, time) do
      response = Matchmaking.handle_info({:receive_video_time, time}, state)

      {:noreply, state} = response

      state
    end

    defp handle_start_next_round(state) do
      response = Matchmaking.handle_info(:start_next_round, state)

      {:noreply, state} = response

      state
    end

    defp handle_round_finished(state, ref, round) do
      response = Matchmaking.handle_info({:DOWN, ref, :process, nil, {:shutdown, round}}, state)

      {:noreply, state} = response

      state
    end

    defp handle_round_crashed(state) do
      response = Matchmaking.handle_info({:DOWN, nil, :process, nil, {:exit, :error}}, state)

      {:noreply, state} = response

      state
    end

    defp assert_videos_are_scheduled(state, scheduled_videos) do
      %{next_rounds: next_rounds} = state

      Enum.each(Enum.with_index(next_rounds), fn {next_round, index} ->
        assert is_valid_round(:scheduled, next_round, %{
                 video: Enum.at(scheduled_videos, index)
               })
      end)
    end

    def get_videos_users(room) do
      Enum.map(room.users_rooms_videos, fn user_room_video ->
        {user_room_video.video, user_room_video.user}
      end)
    end

    defp is_pid_alive(pid) do
      is_pid(pid) and Process.alive?(pid)
    end

    defp get_ref(round) do
      elem(round, 0)
    end

    defp get_pid(round) do
      elem(elem(round, 1), 0)
    end

    defp get_video(round) do
      elem(elem(round, 1), 1)
    end

    defp get_time(round) do
      elem(elem(round, 1), 2)
    end

    defp is_valid_round(:generic, round, video) do
      Enum.all?([
        is_reference(get_ref(round)),
        is_pid_alive(get_pid(round)),
        get_video(round) == video
      ])
    end

    defp is_valid_round(:scheduled, round, args) do
      Enum.all?([
        is_valid_round(:generic, round, args.video),
        get_time(round) == 0
      ])
    end

    defp is_valid_round(:prepared, round, args) do
      Enum.all?([
        is_valid_round(:generic, round, args.video),
        get_time(round) == args.time
      ])
    end

    test "handle_call/3 :: :get_state replies with a state", %{state: state} do
      # Exercise
      response = Matchmaking.handle_call(:get_state, nil, state)

      # Verify
      assert {:reply, ^state, ^state} = response
    end

    test "handle_call/3 :: {:schedule_round, %Video{}} is called one time and replies :ok", %{
      state: state
    } do
      # Setup
      :ok = Channels.subscribe(:room, state.room.slug)

      [video_user | _videos_users] = get_videos_users(state.room)

      # Exercise
      new_state = schedule_rounds(state, [video_user])

      # Verify
      state = %{state | next_rounds: state.next_rounds ++ new_state.next_rounds}

      assert new_state == state
      assert_received({:round_scheduled, _scheduled_round})
    end

    test "handle_call/3 :: {:schedule_round, %Video{}} is called some times times and replies :ok",
         %{
           state: state
         } do
      # Setup
      [{_video, _user} | _videos_users] = videos_users = get_videos_users(state.room)

      # Exercise
      new_state = schedule_rounds(state, videos_users)

      # Verify
      state = %{state | next_rounds: state.next_rounds ++ new_state.next_rounds}
      assert new_state == state
    end

    test "handle_call/3 :: :list_next_rounds is called and replies with an empty list of rounds and videos",
         %{state: state} do
      # Exercise
      next_rounds = handle_list_next_rounds(state)

      # Verify
      assert next_rounds == []
    end

    test "handle_call/3 :: :list_next_rounds is called and replies with a list with a single rounds and videos",
         %{state: state, user: user} do
      # Setup
      video = video_fixture()

      state = handle_schedule_round(state, video, user)

      # Exercise
      next_rounds = handle_list_next_rounds(state)

      # Verify
      assert length(next_rounds) == 1

      :ok =
        Enum.zip(next_rounds, [video])
        |> Enum.each(fn {%{round: round, video: round_video}, video} ->
          %Round.Scheduled{
            elapsed_time: 0,
            score: {0, 0},
            time: 0
          } = round

          assert round_video == video
        end)
    end

    test "handle_call/3 :: {:join, pid} is called with no rounds and returns :ok",
         %{state: state} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      self = self()

      # Exercise
      _state = handle_join(state, self)

      # Verify
      assert_receive(:prepare_next_round)
      refute_received({:receive_playback_details, %{}})
    end

    test "handle_call/3 :: {:join, pid} is called with no prepared rounds and returns :ok",
         %{state: state, user: user} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      state =
        state
        |> handle_schedule_round(video, user)

      # Exercise
      _state = handle_join(state, self())

      # Verify
      assert_receive(:prepare_next_round)

      refute_received(
        {:receive_playback_details, %{video_details: %{videoId: ^video_id, time: 0}, user: ^user}}
      )
    end

    test "handle_call/3 :: {:join, pid} is called with a prepared round and returns :ok",
         %{state: state, user: user} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)

      # Exercise
      _state = handle_join(state, self())

      # Verify
      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    test "handle_call/3 :: {:join, pid} is called with a round in progress and returns :ok",
         %{state: state, user: user} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      video_time = 10

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      state =
        state
        |> handle_receive_video_time(video_time)
        |> handle_start_next_round()

      refute_received(:no_more_rounds)

      # Exercise
      # Awaits a couple seconds before joining the room so that we catch a
      # round that is in progress
      Process.sleep(1800)
      _state = handle_join(state, self())

      # Verify
      assert_received({:receive_countdown, 3000})

      assert_receive(
        {:receive_playback_details,
         %{video_details: %{videoId: ^video_id, time: 1}, added_by: ^user, video: ^video}}
      )
    end

    test "handle_call/3 :: {:score, %User{}, :positive} is called once with no alive round process",
         %{
           state: state,
           user: user
         } do
      # Setup
      video = video_fixture()

      video_time = 10

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      state =
        state
        |> handle_receive_video_time(video_time)
        |> handle_start_next_round()

      {_ref, {round_pid, _video, _time, _user}} = state.current_round

      true = Process.exit(round_pid, :kill)

      {:reply, :error, _state} = Matchmaking.handle_call({:score, user, :positive}, nil, state)
    end

    test "handle_call/3 :: {:score, %User{}, :positive} is called once", %{
      state: state,
      user: user
    } do
      # Setup
      video = video_fixture()

      video_time = 10

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      state =
        state
        |> handle_receive_video_time(video_time)
        |> handle_start_next_round()

      users = user_fixtures(10)

      users_scores = generate_score(:positive, users)
      scores = Enum.map(users_scores, fn {_user, score} -> score end)

      # Exercise
      {_users__scores, round, _state} = handle_scores(state, users_scores)

      # Verify
      assert round.score == get_evaluated_score(scores, {0, 0})
    end

    test "handle_call/3 :: {:score, %User{}, :positive} is called many times", %{
      state: state,
      user: user
    } do
      # Setup
      video = video_fixture()

      video_time = 10

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      state =
        state
        |> handle_receive_video_time(video_time)
        |> handle_start_next_round()

      users = user_fixtures(10)

      users_scores = generate_score(:mixed, users)
      scores = Enum.map(users_scores, fn {_user, score} -> score end)

      # Exercise
      {_users_scores, round, _state} = handle_scores(state, users_scores)

      # Verify
      assert round.score == get_evaluated_score(scores, {0, 0})
    end

    test "handle_info/2 :: {:receive_video_time, non_neg_integer()} is called with a single scheduled round state and does not reply",
         %{
           state: state,
           user: user
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)

      video_time = 30

      # Exercise
      state = handle_receive_video_time(state, video_time)

      # Verify
      assert is_valid_round(:prepared, state.current_round, %{video: video, time: video_time})
    end

    test "handle_info/2 :: {:receive_video_time, non_neg_integer()} is called with a prepared round and nine scheduled rounds state and does not reply",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)

      [{%{video_id: video_id} = prepared_video, _user} | scheduled_videos_users] =
        videos_users = get_videos_users(state.room)

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> schedule_rounds(videos_users)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: prepared_video, time: 0})
      assert length(next_rounds) == length(scheduled_videos_users)

      scheduled_videos = Enum.map(scheduled_videos_users, &elem(&1, 0))
      :ok = assert_videos_are_scheduled(state, scheduled_videos)

      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)

      video_time = 30

      # Exercise
      state = handle_receive_video_time(state, video_time)

      # Verify
      assert is_valid_round(:prepared, state.current_round, %{
               video: prepared_video,
               time: video_time
             })
    end

    test "handle_info/2 :: :prepare_next_round is called with empty next rounds list, replies :ok and does not prepare any round",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)

      # Exercise
      new_state = handle_prepare_next_round(state)

      # Verify
      assert new_state == state
      assert_received(:no_more_rounds)
      refute_received({:receive_playback_details, _video_details})
    end

    test "handle_info/2 :: :prepare_next_round is called with a single next round, replies :ok and assigns a current round",
         %{
           state: state,
           user: user
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      state = handle_schedule_round(state, video, user)

      # Exercise
      %{
        current_round: current_round,
        next_rounds: next_rounds
      } = state = handle_prepare_next_round(state)

      # Verify
      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []
      assert state.status == :waiting_for_details
      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    test "handle_info/2 :: :prepare_next_round is called with ten next rounds, replies :ok and assigns a current round",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)

      [{prepared_video, _user} | scheduled_videos_users] =
        videos_users = get_videos_users(state.room)

      state = schedule_rounds(state, videos_users)

      # Exercise
      %{
        current_round: current_round,
        next_rounds: next_rounds
      } = state = handle_prepare_next_round(state)

      %{video_id: video_id} = get_video(current_round)

      # Verify
      assert is_valid_round(:prepared, current_round, %{video: prepared_video, time: 0})
      assert length(next_rounds) == length(scheduled_videos_users)

      scheduled_videos = Enum.map(scheduled_videos_users, &elem(&1, 0))

      :ok = assert_videos_are_scheduled(state, scheduled_videos)

      assert state.status == :waiting_for_details
      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, {:shutdown, %Round.Finished{}} is called and the next round changes",
         %{state: state} do
      # Setup
      :ok = Channels.subscribe(:room, state.room.slug)
      [{video, user} | _videos_users] = get_videos_users(state.room)

      time = 30

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      state =
        state
        |> handle_receive_video_time(time)
        |> handle_start_next_round()

      {ref, {_pid, ^video, ^time, ^user}} = state.current_round

      round = %Round.Finished{}

      # Exercise
      state = handle_round_finished(state, ref, round)

      # Verify
      assert state.current_round == nil
      assert Enum.member?(state.finished_rounds, round)
      assert state.status == :cooldown

      assert_receive({:round_finished, %{round: ^round, user: ^user}})
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, {:shutdown, %Round.Finished{}} is called with a :continue outcome and the next rounds that change belong to the winner user" do
      # Setup
      room = room_fixture()
      videos = videos_fixture(6)
      user = user_fixture()
      winner_user = user_fixture()

      :ok =
        Enum.each(Enum.with_index(videos), fn {video, index} ->
          user =
            case index do
              0 -> winner_user
              2 -> winner_user
              5 -> winner_user
              _ -> user
            end

          user_room_video = %{user: user, room: room, video: video}
          user_room_video_fixture(user_room_video)
        end)

      room = Rooms.preload_room(room, users_rooms_videos: [:video, :user])

      state = Matchmaking.initial_state(%{room: room})

      :ok = Channels.subscribe(:room, state.room.slug)
      [{video, _user} | _videos_users_tail] = videos_users = get_videos_users(state.room)

      time = 30

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> schedule_rounds(videos_users)
        |> handle_prepare_next_round()

      {_ref, {_pid, _video, _time, ^winner_user}} = current_round
      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      # assert state.next_rounds == videos_users_tail

      winner_queued_rounds =
        Enum.filter(next_rounds, fn {_ref, {_pid, _video, _time, user}} ->
          user == winner_user
        end)

      assert length(winner_queued_rounds) == 2

      state =
        state
        |> handle_receive_video_time(time)
        |> handle_start_next_round()

      {ref, {_pid, ^video, ^time, ^winner_user}} = state.current_round

      round = %Round.Finished{outcome: :continue, score: {10, 0}, elapsed_time: time}

      # Exercise
      state = handle_round_finished(state, ref, round)

      assert Enum.take(state.next_rounds, length(winner_queued_rounds)) == winner_queued_rounds

      # # Verify
      assert state.current_round == nil
      assert Enum.member?(state.finished_rounds, round)
      assert state.status == :cooldown

      assert_receive({:round_finished, %{round: ^round, user: ^winner_user}})
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, {:shutdown, %Round.Finished{}} is called with a :thrown outcome and the next rounds that change belong to the user that was waiting" do
      # Setup
      room = room_fixture()
      videos = videos_fixture(6)
      user = user_fixture()
      waiting_user = user_fixture()

      :ok =
        Enum.each(Enum.with_index(videos), fn {video, index} ->
          user =
            case index do
              2 -> waiting_user
              3 -> waiting_user
              5 -> waiting_user
              _ -> user
            end

          user_room_video = %{user: user, room: room, video: video}
          user_room_video_fixture(user_room_video)
        end)

      room = Rooms.preload_room(room, users_rooms_videos: [:video, :user])

      state = Matchmaking.initial_state(%{room: room})

      :ok = Channels.subscribe(:room, state.room.slug)
      [{video, user} | _videos_users_tail] = videos_users = get_videos_users(state.room)

      time = 30

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> schedule_rounds(videos_users)
        |> handle_prepare_next_round()

      {_ref, {_pid, _video, _time, ^user}} = current_round
      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      # assert state.next_rounds == videos_users_tail

      waiting_user_queued_rounds =
        Enum.filter(next_rounds, fn {_ref, {_pid, _video, _time, user}} ->
          user == waiting_user
        end)

      assert length(waiting_user_queued_rounds) == 3

      state =
        state
        |> handle_receive_video_time(time)
        |> handle_start_next_round()

      {ref, {_pid, ^video, ^time, ^user}} = state.current_round

      round = %Round.Finished{outcome: :thrown, score: {0, 10}, elapsed_time: time}

      # Exercise
      state = handle_round_finished(state, ref, round)

      assert Enum.take(state.next_rounds, length(waiting_user_queued_rounds)) ==
               waiting_user_queued_rounds

      # # Verify
      assert state.current_round == nil
      assert Enum.member?(state.finished_rounds, round)
      assert state.status == :cooldown

      assert_receive({:round_finished, %{round: ^round, user: ^user}})
    end

    test "handle_info/2 :: {:DOWN, ref, :process, pid, reason} is called and a crashed round is registered",
         %{state: state} do
      :ok = Channels.subscribe(:room, state.room.slug)
      [{video, user} | _videos_users] = get_videos_users(state.room)

      time = 30

      %{current_round: current_round, next_rounds: next_rounds} =
        state =
        state
        |> handle_schedule_round(video, user)
        |> handle_prepare_next_round()

      assert is_valid_round(:prepared, current_round, %{video: video, time: 0})
      assert next_rounds == []

      state =
        state
        |> handle_receive_video_time(time)
        |> handle_start_next_round()

      {_ref, {_pid, ^video, ^time, ^user}} = crashed_round = state.current_round

      state = handle_round_crashed(state)

      assert state.current_round == nil
      assert Enum.member?(state.crashed_rounds, crashed_round)
      assert state.status == :cooldown
    end
  end
end
