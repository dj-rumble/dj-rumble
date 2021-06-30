defmodule DjRumble.Rooms.Matchmaking do
  @moduledoc """
  The Specific Matchmaking Server implementation
  """
  use GenServer, restart: :transient

  require Logger

  alias DjRumble.Accounts.User
  alias DjRumble.Chats.ChatServer
  alias DjRumble.Rooms.Video

  alias DjRumble.Rounds.{
    Round,
    RoundServer,
    RoundSupervisor
  }

  alias DjRumble.Rooms.Video
  alias DjRumbleWeb.Channels

  @time_between_rounds :timer.seconds(3)
  @countdown_before_rounds :timer.seconds(3)

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  def create_round(server, video, user) do
    GenServer.call(server, {:schedule_round, {video, user}})
  end

  def join(server, pid) do
    GenServer.call(server, {:join, pid})
  end

  def list_next_rounds(server) do
    GenServer.call(server, :list_next_rounds)
  end

  def get_current_round(server) do
    GenServer.call(server, :get_current_round)
  end

  def score(server, user, type) do
    GenServer.call(server, {:score, user, type})
  end

  def initial_state(args) do
    %{
      room: args.room,
      current_round: {nil, {nil, nil, nil, nil}},
      finished_rounds: [],
      next_rounds: [],
      crashed_rounds: [],
      status: :idle,
      chat_server: args.chat_server
    }
  end

  @impl GenServer
  def init({room, chat_server} = _init_arg) do
    state = initial_state(%{room: room, chat_server: chat_server})

    {:ok, state, :hibernate}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call({:schedule_round, {video, user}}, _from, state) do
    state = %{
      state
      | next_rounds: state.next_rounds ++ [schedule_round(video, state.room, user)]
    }

    :ok = send_announcement(state, :round_scheduled, video, user)

    Logger.info(fn ->
      "Scheduled a round for video title: #{video.title}, added by user: #{user.username}"
    end)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:list_next_rounds, _from, state) do
    next_rounds =
      Enum.map(state.next_rounds, fn {_ref, {pid, video, _time, user}} ->
        %{round: RoundServer.get_round(pid), video: video, user: user}
      end)

    {:reply, next_rounds, state}
  end

  @impl GenServer
  def handle_call(:get_current_round, _from, state) do
    response =
      case state.current_round do
        {_ref, {nil, _video, _time, _user}} ->
          video =
            Video.video_placeholder(%{
              title: "Waiting for the next round"
            })

          %{round: nil, video: video, user: nil}

        {_ref, {pid, video, _time, user}} ->
          %{round: RoundServer.get_round(pid), video: video, user: user}
      end

    {:reply, response, state}
  end

  @impl GenServer
  def handle_call({:join, pid}, _from, state) do
    case state.status do
      :idle ->
        :ok = Process.send(self(), :prepare_next_round, [])

      :waiting_for_details ->
        {_ref, {_pid, video, 0 = time, _user}} = state.current_round

        Logger.info(fn -> "Sending a playback details request." end)

        :ok = request_playback_details(state.room.slug, video, time)

      :cooldown ->
        nil

      :countdown ->
        nil

      :playing ->
        {_ref, {round_pid, video, _time, user}} = state.current_round
        Logger.info(fn -> "Sending current round details." end)

        :ok = RoundServer.on_player_join(round_pid)

        round = RoundServer.get_round(round_pid)

        :ok = send_playback_details(pid, round, video, user)
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:score, user, type}, _from, state) do
    {_ref, {round_pid, video, _time, _user}} = state.current_round

    response =
      case Process.alive?(round_pid) do
        true ->
          %Round.InProgress{} = round = RoundServer.score(round_pid, user, type)

          :ok = send_announcement(state, :score, video, user, type, round)

          round

        false ->
          :error
      end

    {:reply, response, state}
  end

  @impl GenServer
  def handle_info(:start_next_round, state) do
    state = start_next_round(state)

    Logger.info(fn -> "Started the next round" end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:prepare_next_round, state) do
    state = prepare_next_round(state)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:receive_video_time, time}, state) do
    :ok = Channels.unsubscribe(:matchmaking_details_request, state.room.slug)

    state =
      case state.current_round do
        {ref, {pid, video, 0 = _time, user}} ->
          parsed_time = trunc(time)

          :ok = RoundServer.set_round_time(pid, parsed_time)

          Logger.info(fn -> "Receives video time #{time} and truncates it to #{parsed_time}." end)

          :ok =
            Channels.broadcast(
              :player_is_ready,
              state.room.slug,
              {:receive_countdown, @countdown_before_rounds}
            )

          # Sets a 1200 milliseconds gap to let the video player be ready after
          # the ui overlay with round info disappears.
          Process.send_after(self(), :start_next_round, @countdown_before_rounds + 1200)

          %{
            state
            | current_round: {ref, {pid, video, parsed_time, user}},
              status: :countdown
          }

        # This case is needed because race conditions happen when the broadcasted pids answer
        {_ref, {_pid, _video, _time, _user}} ->
          state
      end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, %Round.Finished{} = round}}, state) do
    {dislikes, likes} = round.score

    # coveralls-ignore-start
    Logger.info(fn ->
      "Round finished, id: #{round.id}, score: {#{dislikes}, #{likes}}, outcome: #{round.outcome}"
    end)

    # coveralls-ignore-stop

    # :ok = Gladiators.register_battle_result({Gladiators.get_gladiator(left.id), Gladiators.get_gladiator(right.id)}, battle.outcome)

    Process.demonitor(ref)

    {_ref, {_pid, video, _time, finished_round_user}} = state.current_round

    finished_video =
      Video.video_placeholder(%{
        title: "Waiting for the next round"
      })

    video_details = %{title: video.title}

    :ok = broadcast_lobby(state, nil, nil)

    :ok =
      Channels.broadcast(
        :room,
        state.room.slug,
        {:round_finished,
         %{
           video_details: video_details,
           video: finished_video,
           round: round,
           user: finished_round_user
         }}
      )

    {current_user_rounds, other_rounds} =
      Enum.reduce(state.next_rounds, {[], []}, fn {_ref, {_pid, _video, _time, user}} = round,
                                                  {current_user_rounds, other_rounds} ->
        case user == finished_round_user do
          true -> {current_user_rounds ++ [round], other_rounds}
          false -> {current_user_rounds, other_rounds ++ [round]}
        end
      end)

    next_rounds =
      case round.outcome do
        :continue ->
          current_user_rounds ++ other_rounds

        :thrown ->
          other_rounds ++ current_user_rounds
      end

    state = %{
      state
      | current_round: {nil, {nil, nil, nil, nil}},
        finished_rounds: [round | state.finished_rounds],
        next_rounds: next_rounds ++ [schedule_round(video, state.room, finished_round_user)],
        status: :cooldown
    }

    Process.send_after(self(), :prepare_next_round, @time_between_rounds)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    # coveralls-ignore-start
    Logger.info(fn ->
      "Round with pid '#{inspect(pid)}' crashed. Reason: #{inspect(reason)}. Last local state: #{
        inspect(state)
      }."
    end)

    # coveralls-ignore-stop

    # :ok = Gladiators.register_battle_result({Gladiators.get_gladiator(left.id), Gladiators.get_gladiator(right.id)}, :draw)

    state = %{
      state
      | current_round: {nil, {nil, nil, nil, nil}},
        crashed_rounds: [state.current_round | state.crashed_rounds],
        status: :cooldown
    }

    Process.send_after(self(), :prepare_next_round, @time_between_rounds)

    {:noreply, state}
  end

  defp schedule_round(video, room, user) do
    %{slug: slug} = room
    {:ok, pid} = RoundSupervisor.start_round_server(RoundSupervisor, {slug})
    ref = Process.monitor(pid)

    :ok = Channels.broadcast(:room, slug, {:round_scheduled, RoundServer.get_round(pid)})

    {ref, {pid, video, 0, user}}
  end

  defp prepare_next_round(state) do
    %{slug: slug} = state.room

    case state.next_rounds do
      [] ->
        :ok = Channels.broadcast(:player_is_ready, slug, :no_more_rounds)

        %{state | status: :idle}

      [{_ref, {_pid, video, 0 = time, _user}} = next_round | next_rounds] ->
        :ok = Channels.unsubscribe(:matchmaking_details_request, slug)
        :ok = Channels.subscribe(:matchmaking_details_request, slug)

        state = %{
          state
          | current_round: next_round,
            next_rounds: next_rounds,
            status: :waiting_for_details
        }

        :ok = request_playback_details(slug, video, time)

        Logger.info(fn -> "Prepared a next round" end)

        state
    end
  end

  defp request_playback_details(slug, video, time) do
    Channels.broadcast(
      :player_is_ready,
      slug,
      {:request_playback_details, %{videoId: video.video_id, time: time}}
    )
  end

  defp send_playback_details(pid, round, video, user) do
    video_details = %{time: round.elapsed_time, videoId: video.video_id}

    :ok =
      Process.send(
        pid,
        {:receive_playback_details,
         %{round: round, video: video, video_details: video_details, added_by: user}},
        []
      )
  end

  defp start_next_round(state) do
    # Do something with the current round? YES, check if exists

    # Enum.each(state.current_rounds, fn {ref, {pid, {left, right}}} ->
    Logger.info(fn -> "Starting round" end)

    #   battle =
    #     case BattleServer.get_battle(pid) do
    #       %Battle.Finished{} = battle -> %{battle | outcome: :draw}
    #
    #       %Battle.InProgress{} = battle ->
    #         %Battle.Finished{
    #           id: battle.id,
    #           fighters: battle.fighters,
    #           outcome: :draw,
    #           log: battle.log
    #         }
    #     end
    #
    #   :ok =
    #     Gladiators.register_battle_result(
    #       {Gladiators.get_gladiator(left.id), Gladiators.get_gladiator(right.id)},
    #       battle.outcome
    #     )
    {_ref, {pid, video, _time, user}} = state.current_round

    # Worths to check if its dead, if not, use the next function:
    # RoundSupervisor.terminate_round_server(RoundSupervisor, pid)

    :ok = RoundServer.start_round(pid)

    state = %{state | status: :playing}

    :ok = send_announcement(state, :round_started, video, user)

    :ok = broadcast_lobby(state, video, user)

    :ok =
      Channels.broadcast(
        :player_is_ready,
        state.room.slug,
        {:round_started,
         %{
           round: RoundServer.get_round(pid),
           video_details: %{videoId: video.video_id, time: 0},
           video: video,
           added_by: user
         }}
      )

    state
  end

  defp send_announcement(state, :round_started, %Video{} = video, %User{} = user) do
    ChatServer.new_video_message(state.chat_server, video, user, :playing)
  end

  defp send_announcement(state, :round_scheduled, %Video{} = video, %User{} = user) do
    case state.current_round do
      {_ref, {_pid, _current_video, _time, ^user}} ->
        # Although the video added by this Dj is at the end of the queue, it is
        # likely to change if a :continue outcome is determined at the end of
        # the current round. We count current Dj videos to predict a place at
        # the queue.
        remaining_videos =
          get_current_dj_rounds(state.next_rounds, user)
          |> length()

        :ok =
          ChatServer.new_video_message(
            state.chat_server,
            video,
            user,
            {:scheduled, :dj, remaining_videos}
          )

      _ ->
        # This is not the Dj player, the video will remain at the end of the
        # queue.
        remaining_videos = length(state.next_rounds)

        :ok =
          ChatServer.new_video_message(
            state.chat_server,
            video,
            user,
            {:scheduled, :spectator, remaining_videos}
          )
    end
  end

  defp send_announcement(
         state,
         :score,
         %Video{} = video,
         %User{} = user,
         score_type,
         %Round.InProgress{} = round
       ) do
    role =
      case state.current_round do
        {_ref, {_pid, _current_video, _time, ^user}} ->
          :dj

        _round ->
          :spectator
      end

    :ok =
      ChatServer.new_score_message(
        state.chat_server,
        video,
        user,
        {score_type, role, round}
      )
  end

  defp get_current_dj_rounds(rounds, %User{} = user) do
    Enum.filter(rounds, fn {_ref, {_pid, _current_video, _time, round_user}} ->
      user == round_user
    end)
  end

  defp broadcast_lobby(state, video, user) do
    :ok =
      Channels.broadcast(
        :lobby,
        state.room.slug,
        {:receive_current_player,
         %{
           current_round: %{video: video, added_by: user},
           room: state.room,
           status: state.status,
           videos: Enum.map(state.room.users_rooms_videos, & &1.video)
         }}
      )
  end
end
