defmodule DjRumble.Rooms.Matchmaking do
  @moduledoc """
  The Specific Matchmaking Server implementation
  """
  use GenServer, restart: :transient

  require Logger

  alias DjRumble.Rounds.{
    Round,
    RoundServer,
    RoundSupervisor
  }

  alias DjRumbleWeb.Channels

  @time_between_rounds :timer.seconds(3)
  @countdown_before_rounds :timer.seconds(3)

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def get_state(server) do
    GenServer.call(server, :get_state)
  end

  def create_round(server, video) do
    GenServer.call(server, {:schedule_round, video})
  end

  def start_round(server) do
    GenServer.call(server, :prepare_initial_round)
  end

  def join(server, pid) do
    GenServer.cast(server, {:join, pid})
  end

  @impl GenServer
  def init({room} = _init_arg) do
    state = %{
      room: room,
      current_round: nil,
      finished_rounds: [],
      next_rounds: [],
      crashed_rounds: []
    }

    {:ok, state, :hibernate}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_call({:schedule_round, video}, _from, state) do
    state = %{
      state
      | next_rounds: state.next_rounds ++ [schedule_round(video, state.room)]
    }

    Logger.info(fn -> "Scheduled a round for video title: #{video.title}" end)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:prepare_initial_round, _from, state) do
    Logger.info(fn ->
      "Preparing an initial round."
    end)

    state = prepare_next_round(state)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_cast({:join, pid}, state) do
    case state.current_round do
      nil ->
        :ok = Channels.broadcast(:player_is_ready, state.room.slug, :no_more_rounds)

      {_ref, {round_pid, %{video_id: video_id}, _time}} ->
        Logger.info(fn -> "Sending current round details." end)

        elapsed_time =
          case RoundServer.get_round(round_pid) do
            %Round.InProgress{elapsed_time: elapsed_time} -> elapsed_time
            round -> round.elapsed_time
          end

        :ok =
          Process.send(
            pid,
            {:receive_playback_details, %{time: elapsed_time, videoId: video_id}},
            []
          )
    end

    {:noreply, state}
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
        {ref, {pid, video, 0 = _time}} ->
          parsed_time = trunc(time)

          :ok = RoundServer.set_round_time(pid, parsed_time + 1)

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
            | current_round: {ref, {pid, video, parsed_time}}
          }

        # This case is needed because race conditions happen when the broadcasted pids answer
        {_ref, {_pid, _video, _}} ->
          state
      end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, %Round.Finished{} = round}}, state) do
    {dislikes, likes} = round.score

    Logger.info(fn ->
      "Round finished, id: #{round.id}, score: {#{dislikes}, #{likes}}, outcome: #{round.outcome}"
    end)

    # :ok = Gladiators.register_battle_result({Gladiators.get_gladiator(left.id), Gladiators.get_gladiator(right.id)}, battle.outcome)

    :ok = Channels.broadcast(:room, state.room.slug, {:round_finished, round})

    Process.demonitor(ref)

    {_ref, {_pid, video, _}} = state.current_round

    state = %{
      state
      | current_round: nil,
        finished_rounds: [round | state.finished_rounds],
        next_rounds: state.next_rounds ++ [schedule_round(video, state.room)]
    }

    Process.send_after(self(), :prepare_next_round, @time_between_rounds)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    # {_, {round_pid, video}} = Map.get(state.current_round, ref)

    Logger.error(fn ->
      "Round with pid '#{inspect(pid)}' crashed. Reason: #{inspect(reason)}. Last local state: #{
        inspect(state)
      }."
    end)

    # :ok = Gladiators.register_battle_result({Gladiators.get_gladiator(left.id), Gladiators.get_gladiator(right.id)}, :draw)

    state = %{
      state
      | current_round: nil,
        crashed_rounds: [state.current_round | state.crashed_rounds]
    }

    Process.send_after(self(), :prepare_next_round, @time_between_rounds)

    {:noreply, state}
  end

  defp schedule_round(video, room) do
    %{slug: slug} = room
    {:ok, pid} = RoundSupervisor.start_round_server(RoundSupervisor, {slug, 0})
    ref = Process.monitor(pid)

    :ok = Channels.broadcast(:room, slug, {:round_scheduled, RoundServer.get_round(pid)})

    {ref, {pid, video, 0}}
  end

  defp prepare_next_round(state) do
    %{slug: slug} = state.room

    case state.next_rounds do
      [] ->
        :ok = Channels.broadcast(:player_is_ready, slug, :no_more_rounds)

        state

      [{_ref, {_pid, video, 0 = time}} = next_round | next_rounds] ->
        :ok = Channels.subscribe(:matchmaking_details_request, slug)

        :ok = request_playback_details(slug, video, time)

        Logger.info(fn -> "Prepared a next round" end)

        %{
          state
          | current_round: next_round,
            next_rounds: next_rounds
        }
    end
  end

  defp request_playback_details(slug, video, time) do
    Channels.broadcast(
      :player_is_ready,
      slug,
      {:request_playback_details, %{videoId: video.video_id, time: time}}
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
    {_ref, {pid, video, _time}} = state.current_round

    # Worths to check if its dead, if not, use the next function:
    # RoundSupervisor.terminate_round_server(RoundSupervisor, pid)

    :ok = RoundServer.start_round(pid)

    :ok =
      Channels.broadcast(
        :player_is_ready,
        state.room.slug,
        {:round_started,
         %{
           round: RoundServer.get_round(pid),
           video_details: %{videoId: video.video_id, time: 0, title: video.title}
         }}
      )

    state
  end
end
