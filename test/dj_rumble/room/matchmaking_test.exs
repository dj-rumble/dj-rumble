defmodule DjRumble.Room.MatchmakingTest do
  @moduledoc """
  Matchmaking tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  describe "matchmaking client interface" do
    alias DjRumble.Rooms.Matchmaking

    setup do
      %{room: room} =
        room_videos_fixture(
          %{room: room_fixture(), videos: videos_fixture()},
          %{preload: true}
        )

      matchmaking_genserver_pid = start_supervised!({Matchmaking, {room}})

      %{room: room, pid: matchmaking_genserver_pid}
    end

    @tag wip: true
    test "start_link/1 starts a matchmaking server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    @tag wip: true
    test "get_room/1 returns a room", %{pid: pid, room: room} do
      assert Matchmaking.get_room(pid) == room
    end

    @tag wip: true
    test "create_round/1 returns :ok", %{pid: pid, room: room} do
      [video | _videos] = room.videos
      assert Matchmaking.create_round(pid, video) == :ok
    end

    @tag wip: true
    test "start_round/1 returns :ok", %{pid: pid, room: room} do
      [video | _videos] = room.videos
      assert Matchmaking.create_round(pid, video) == :ok

      assert Matchmaking.start_round(pid) == :ok
    end

    @tag wip: true
    test "start_round/1 returns :ok when there are no scheduled rounds", %{pid: pid} do
      assert Matchmaking.start_round(pid) == :ok
    end
  end

  describe "matchmaking server implementation" do
    alias DjRumble.Rooms.Matchmaking

    setup do
      room = room_fixture(%{}, %{preload: true})

      state = %{
        room: room,
        current_round: nil,
        finished_rounds: [],
        next_rounds: [],
        crashed_rounds: []
      }

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
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}")

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

    @tag wip: true
    test "handle_call/3 :: :get_room replies with a room", %{state: state} do
      # Exercise
      response = Matchmaking.handle_call(:get_room, nil, state)
      %{room: room} = state

      # Verify
      assert {:reply, room, state} == response
    end

    @tag wip: true
    test "handle_call/3 :: {:schedule_round, %Video{}} is called one time and replies :ok", %{
      state: state
    } do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}")
      video = video_fixture()

      # Exercise
      _state =
        handle_schedule_round(
          state,
          video,
          [
            &assert(&1 == nil)
          ],
          [
            &assert(length(&1) == 1),
            &assert(is_valid_round(:scheduled, hd(&1), %{video: video}))
          ]
        )

      assert_received({:round_scheduled, _scheduled_round})
    end

    @tag wip: true
    test "handle_call/3 :: {:schedule_round, %Video{}} is called ten times and replies :ok", %{
      state: state
    } do
      # Setup
      videos = videos_fixture(10)
      # Exercise & Verify
      schedule_rounds(state, videos)
    end

    @tag wip: true
    test "handle_call/3 :: :prepare_initial_round is called with empty next rounds list, replies :ok and does not prepare any round",
         %{
           state: state
         } do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")

      # Exercise
      new_state = handle_prepare_initial_round(state)

      # Verify
      assert new_state == state
      assert_received(:no_more_rounds)
      refute_received({:receive_playback_details, _video_details})
    end

    @tag wip: true
    test "handle_call/3 :: :prepare_initial_round is called with a single next round, replies :ok and assigns a current round",
         %{
           state: state
         } do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
      %{video_id: video_id} = video = video_fixture()

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
      assert_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    @tag wip: true
    test "handle_call/3 :: :prepare_initial_round is called with ten next rounds, replies :ok and assigns a current round",
         %{
           state: state
         } do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
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
      assert_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    @tag wip: true
    test "handle_cast/2 :: {:join, pid} is called with no rounds and returns :ok",
         %{state: state} do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")

      # Exercise
      response = Matchmaking.handle_cast({:join, self()}, state)

      {:noreply, _state} = response

      # Verify
      assert_received(:no_more_rounds)
      refute_received({:receive_playback_details, %{}})
    end

    @tag wip: true
    test "handle_cast/2 :: {:join, pid} is called with no prepared rounds and returns :ok",
         %{state: state} do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
      %{video_id: video_id} = video = video_fixture()

      state =
        state
        |> handle_schedule_round(video)

      # Exercise
      response = Matchmaking.handle_cast({:join, self()}, state)

      {:noreply, _state} = response

      # Verify
      assert_received(:no_more_rounds)
      refute_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
    end

    @tag wip: true
    test "handle_cast/2 :: {:join, pid} is called with a prepared round and returns :ok",
         %{state: state} do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
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

      assert_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)

      # Exercise
      response = Matchmaking.handle_cast({:join, self()}, state)

      {:noreply, _state} = response

      # Verify
      assert_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)
    end

    @tag wip: true
    test "handle_cast/2 :: {:join, pid} is called with a round in progress and returns :ok",
         %{state: state} do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
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
      Process.sleep(2000)
      response = Matchmaking.handle_cast({:join, self()}, state)

      {:noreply, _state} = response

      # Verify
      assert_received({:receive_countdown, 3000})
      assert_receive({:receive_playback_details, %{videoId: ^video_id, time: 1}})
    end

    @tag wip: true
    test "handle_info/2 :: {:receive_video_time, non_neg_integer()} is called with a single scheduled round state and does not reply",
         %{
           state: state
         } do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
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

      assert_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
      refute_received(:no_more_rounds)

      video_time = 30

      # Exercise
      state = handle_receive_video_time(state, video_time)

      # Verify
      assert is_valid_round(:prepared, state.current_round, %{video: video, time: video_time})
    end

    @tag wip: true
    test "handle_info/2 :: {:receive_video_time, non_neg_integer()} is called with a prepared round and nine scheduled rounds state and does not reply",
         %{
           state: state
         } do
      # Setup
      :ok = Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{state.room.slug}:ready")
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

      assert_received({:receive_playback_details, %{videoId: ^video_id, time: 0}})
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
  end
end
