defmodule DjRumble.Room.MatchmakingTest do
  @moduledoc """
  Matchmaking tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  alias DjRumble.Rooms.Video

  alias DjRumble.Rounds.Round

  describe "matchmaking client interface" do
    alias DjRumble.Rooms.Matchmaking

    setup do
      %{room: room} =
        room_videos_fixture(
          %{room: room_fixture(), videos: videos_fixture()},
          %{preload: true}
        )

      matchmaking_genserver_pid = start_supervised!({Matchmaking, {room}})

      initial_state = Matchmaking.initial_state(%{room: room})

      %{pid: matchmaking_genserver_pid, room: room, state: initial_state}
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

    defp start_next_round(server) do
      Process.send(server, :start_next_round, [])
    end

    test "start_link/1 starts a matchmaking server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "get_state/1 returns a state", %{pid: pid, state: state} do
      assert Matchmaking.get_state(pid) == state
    end

    test "create_round/1 returns :ok", %{pid: pid, room: room} do
      [video | _videos] = room.videos
      assert Matchmaking.create_round(pid, video) == :ok
    end

    test "list_next_rounds/1 returns a list of rounds and videos", %{pid: pid, state: state} do
      # Setup
      %{room: %{videos: videos}} = state
      :ok = Enum.each(videos, &assert(Matchmaking.create_round(pid, &1) == :ok))

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
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there is a next round",
         %{pid: pid, state: state} do
      # Setup
      [video | _videos] = state.room.videos
      assert Matchmaking.create_round(pid, video) == :ok

      # Exercise
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video} = current_round
    end

    test "get_current_round/1 returns an empty round with a placeholder video when there are some next rounds",
         %{pid: pid, state: state} do
      # Setup
      %{videos: videos} = state.room
      :ok = Enum.each(videos, &assert(Matchmaking.create_round(pid, &1) == :ok))

      # Exercise
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      video = placeholder_video()
      %{round: nil, video: ^video} = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a scheduled round with a video when there is a current round",
         %{pid: pid, state: state} do
      # Setup
      [video | _videos] = state.room.videos

      :ok = Matchmaking.create_round(pid, video)
      :ok = prepare_next_round(pid)

      # Exercise
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        }
      } = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a scheduled round with a video when there are some current rounds",
         %{pid: pid, state: state} do
      # Setup
      %{videos: [video | _videos] = videos} = state.room
      :ok = Enum.each(videos, &assert(Matchmaking.create_round(pid, &1) == :ok))
      :ok = prepare_next_round(pid)

      # Exercise
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.Scheduled{
          elapsed_time: 0,
          score: {0, 0},
          time: 0
        }
      } = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a round that is in progress with a video when there is a next round",
         %{pid: pid, state: state} do
      # Setup
      %{videos: [video | _videos]} = state.room
      :ok = Matchmaking.create_round(pid, video)
      :ok = prepare_next_round(pid)
      time = 30
      :ok = receive_video_time(pid, time)
      :ok = start_next_round(pid)

      # Exercise
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        }
      } = current_round
    end

    @tag wip: true
    test "get_current_round/1 returns a round that is in progress with a video when there are some current rounds",
         %{pid: pid, state: state} do
      # Setup
      %{videos: [video | _videos] = videos} = state.room
      :ok = Enum.each(videos, &assert(Matchmaking.create_round(pid, &1) == :ok))
      :ok = prepare_next_round(pid)
      time = 30
      :ok = receive_video_time(pid, time)
      :ok = start_next_round(pid)

      # Exercise
      current_round = Matchmaking.get_current_round(pid)

      # Verify
      %{video: ^video} = current_round

      %{
        round: %Round.InProgress{
          elapsed_time: 0,
          score: {0, 0},
          time: ^time
        }
      } = current_round
    end
  end

  describe "matchmaking server implementation" do
    alias DjRumble.Rooms.Matchmaking
    alias DjRumble.Rounds.Round
    alias DjRumbleWeb.Channels

    setup do
      room = room_fixture(%{}, %{preload: true})

      state = Matchmaking.initial_state(%{room: room})

      %{room: room, state: state}
    end

    defp handle_schedule_round(state, video, callbacks \\ [], next_round_callbacks \\ []) do
      response = Matchmaking.handle_call({:schedule_round, video}, nil, state)

      assert {:reply, :ok, state} = response

      Enum.each(callbacks, & &1.(state.current_round))
      Enum.each(next_round_callbacks, & &1.(state.next_rounds))

      state
    end

    defp schedule_rounds(state, videos, _callbacks \\ [], _next_round_callbacks \\ []) do
      :ok = Channels.subscribe(:room, state.room.slug)

      Enum.reduce(Enum.with_index(videos), state, fn {video, index}, acc_state ->
        state =
          handle_schedule_round(
            acc_state,
            video,
            [&assert(&1 == nil)],
            [
              &assert(length(&1) == index + 1),
              &assert(is_valid_round(:scheduled, Enum.at(&1, index), %{video: video}))
            ]
          )

        assert_received({:round_scheduled, _scheduled_round})
        state
      end)
    end

    defp handle_prepare_initial_round(state, callbacks \\ [], next_round_callbacks \\ []) do
      response = Matchmaking.handle_call(:prepare_initial_round, nil, state)

      assert {:reply, :ok, state} = response

      Enum.each(callbacks, & &1.(state.current_round))
      Enum.each(next_round_callbacks, & &1.(state.next_rounds))

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
      video = video_fixture()

      # Exercise
      new_state = schedule_rounds(state, [video])

      # Verify
      state = %{state | next_rounds: state.next_rounds ++ new_state.next_rounds}

      assert new_state == state
      assert_received({:round_scheduled, _scheduled_round})
    end

    test "handle_call/3 :: {:schedule_round, %Video{}} is called ten times and replies :ok", %{
      state: state
    } do
      # Setup
      videos = videos_fixture(10)

      # Exercise
      new_state = schedule_rounds(state, videos)

      # Verify
      state = %{state | next_rounds: state.next_rounds ++ new_state.next_rounds}
      assert new_state == state
    end

    test "handle_call/3 :: :prepare_initial_round is called with empty next rounds list, replies :ok and does not prepare any round",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)

      # Exercise
      new_state = handle_prepare_initial_round(state)

      # Verify
      assert new_state == state
      assert_received(:no_more_rounds)
      refute_received({:receive_playback_details, _video_details})
    end

    test "handle_call/3 :: :prepare_initial_round is called with a single next round, replies :ok and assigns a current round",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      state =
        state
        |> handle_schedule_round(video)
        # Exercise
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: video, time: 0}))
          ],
          [&assert(&1 == [])]
        )

      # Verify
      assert state.status == :waiting_for_details
      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    test "handle_call/3 :: :prepare_initial_round is called with ten next rounds, replies :ok and assigns a current round",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      [prepared_video | scheduled_videos] = videos = videos_fixture(10)

      state =
        state
        |> schedule_rounds(videos)
        # Exercise
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: prepared_video, time: 0}))
          ],
          [
            &assert(length(&1) == length(scheduled_videos)),
            &Enum.each(Enum.with_index(&1), fn {next_round, index} ->
              assert is_valid_round(:scheduled, next_round, %{
                       video: Enum.at(scheduled_videos, index)
                     })
            end)
          ]
        )

      %{video_id: video_id} = get_video(state.current_round)

      # Verify
      assert state.status == :waiting_for_details
      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    test "handle_call/3 :: :list_next_rounds is called and replies with an empty list of rounds and videos",
         %{state: state} do
      # Exercise
      next_rounds = handle_list_next_rounds(state)

      # Verify
      assert next_rounds == []
    end

    test "handle_call/3 :: :list_next_rounds is called and replies with a list with a single rounds and videos",
         %{state: state} do
      # Setup
      video = video_fixture()

      state = handle_schedule_round(state, video)

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

    @tag wip: true
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
         %{state: state} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      state =
        state
        |> handle_schedule_round(video)

      # Exercise
      _state = handle_join(state, self())

      # Verify
      assert_receive(:prepare_next_round)
      refute_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
    end

    test "handle_call/3 :: {:join, pid} is called with a prepared round and returns :ok",
         %{state: state} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      state =
        state
        |> handle_schedule_round(video)
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: video, time: 0}))
          ],
          [&assert(&1 == [])]
        )

      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)

      # Exercise
      _state = handle_join(state, self())

      # Verify
      assert_received({:request_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    test "handle_call/3 :: {:join, pid} is called with a round in progress and returns :ok",
         %{state: state} do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      video_time = 10

      state =
        state
        |> handle_schedule_round(video)
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: video, time: 0}))
          ],
          [&assert(&1 == [])]
        )
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
      assert_receive({:receive_playback_details, %{videoId: ^video_id, time: 1}})
    end

    test "handle_info/2 :: {:receive_video_time, non_neg_integer()} is called with a single scheduled round state and does not reply",
         %{
           state: state
         } do
      # Setup
      :ok = Channels.subscribe(:player_is_ready, state.room.slug)
      %{video_id: video_id} = video = video_fixture()

      state =
        state
        |> handle_schedule_round(video)
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: video, time: 0}))
          ],
          [&assert(&1 == [])]
        )

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
      [%{video_id: video_id} = prepared_video | scheduled_videos] = videos = videos_fixture(10)

      state =
        state
        |> schedule_rounds(videos)
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: prepared_video, time: 0}))
          ],
          [
            &assert(length(&1) == length(scheduled_videos)),
            &Enum.each(Enum.with_index(&1), fn {next_round, index} ->
              assert is_valid_round(:scheduled, next_round, %{
                       video: Enum.at(scheduled_videos, index)
                     })
            end)
          ]
        )

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

    @tag wip: true
    test "handle_info/2 :: {:DOWN, ref, :process, pid, {:shutdown, %Round.Finished{}} is called and the next round changes",
         %{state: state} do
      :ok = Channels.subscribe(:room, state.room.slug)
      [video | _videos] = videos_fixture(10)

      time = 30

      state =
        state
        |> handle_schedule_round(video)
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: video, time: 0}))
          ],
          [&assert(&1 == [])]
        )
        |> handle_receive_video_time(time)
        |> handle_start_next_round()

      {ref, {_pid, _video, _time}} = state.current_round

      round = %Round.Finished{}

      state = handle_round_finished(state, ref, round)

      assert state.current_round == nil
      assert Enum.member?(state.finished_rounds, round)
      assert state.status == :cooldown

      assert_receive({:round_finished, ^round})
    end

    @tag wip: true
    test "handle_info/2 :: {:DOWN, ref, :process, pid, reason} is called and a crashed round is registered",
         %{state: state} do
      :ok = Channels.subscribe(:room, state.room.slug)
      [video | _videos] = videos_fixture(10)

      time = 30

      state =
        state
        |> handle_schedule_round(video)
        |> handle_prepare_initial_round(
          [
            &assert(is_valid_round(:prepared, &1, %{video: video, time: 0}))
          ],
          [&assert(&1 == [])]
        )
        |> handle_receive_video_time(time)
        |> handle_start_next_round()

      {_ref, {_pid, _video, _time}} = crashed_round = state.current_round

      state = handle_round_crashed(state)

      assert state.current_round == nil
      assert Enum.member?(state.crashed_rounds, crashed_round)
      assert state.status == :cooldown
    end
  end
end
