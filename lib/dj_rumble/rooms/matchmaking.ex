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

  @time_between_rounds :timer.seconds(3)
  @countdown_before_rounds :timer.seconds(3)

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def get_room(server \\ __MODULE__) do
    GenServer.call(server, :get_room)
  end

  def create_round(server \\ __MODULE__, video) do
    GenServer.call(server, {:schedule_round, video})
  end

  def start_round(server \\ __MODULE__) do
    GenServer.call(server, :prepare_initial_round)
  end

  def send_playback_details(server \\ __MODULE__, pid) do
    GenServer.cast(server, {:send_playback_details, pid})
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
  def handle_call(:get_room, _from, state) do
    {:reply, state.room, state}
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
  def handle_cast({:send_playback_details, pid}, state) do
    Logger.info(fn -> "Sending current round details." end)

    {_ref, {_pid, %{video_id: video_id}, time}} = state.current_round

    :ok = Process.send(pid, {:receive_playback_details, %{videoId: video_id, time: time}}, [])

    {:noreply, state}
  end

  # @impl GenServer
  # def handle_info(:max_series_length_exceeded, state) do
  #   state = start_next_round(state)

  #   Logger.info(fn ->
  #     "Maximum battle length elapsed, starting the next series"
  #   end)

  #   {:noreply, state}
  # end

  @impl GenServer
  def handle_info(:start_next_round, state) do
    state = start_next_round(state)

    Logger.info(fn -> "Started the next round" end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:prepare_next_round, state) do
    state = prepare_next_round(state)

    Logger.info(fn -> "Prepared a round." end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:receive_video_time, time}, state) do
    :ok =
      Phoenix.PubSub.unsubscribe(
        DjRumble.PubSub,
        "matchmaking:#{state.room.slug}:waiting_for_details"
      )

    parsed_time = trunc(time)
    {ref, {pid, video, 0 = _time}} = state.current_round

    :ok = RoundServer.set_round_time(pid, parsed_time)

    Logger.info(fn -> "Receives video time #{time} and truncates it to #{parsed_time}." end)

    :ok =
      Phoenix.PubSub.broadcast(
        DjRumble.PubSub,
        "room:#{state.room.slug}:ready",
        {:receive_countdown, @countdown_before_rounds}
      )

    Process.send_after(self(), :start_next_round, @countdown_before_rounds)

    state = %{
      state
      | current_round: {ref, {pid, video, parsed_time}}
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, {:shutdown, %Round.Finished{} = round}}, state) do
    {dislikes, likes} = round.score

    Logger.info(fn ->
      "Round finished, id: #{round.id}, score: {#{dislikes}, #{likes}}, outcome: #{round.outcome}"
    end)

    # :ok = Gladiators.register_battle_result({Gladiators.get_gladiator(left.id), Gladiators.get_gladiator(right.id)}, battle.outcome)

    :ok =
      Phoenix.PubSub.broadcast(
        DjRumble.PubSub,
        "room:#{state.room.slug}",
        {:round_finished, round}
      )

    Process.demonitor(ref)

    state = %{
      state
      | current_round: nil,
        finished_rounds: [round | state.finished_rounds]
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
    {:ok, pid} = RoundSupervisor.start_round_server(RoundSupervisor, {slug, 10})
    ref = Process.monitor(pid)

    Phoenix.PubSub.broadcast(
      DjRumble.PubSub,
      "room:#{slug}",
      {:round_scheduled, RoundServer.get_round(pid)}
    )

    {ref, {pid, video, 0}}
  end

  defp prepare_next_round(state) do
    %{slug: slug} = state.room

    case state.next_rounds do
      [] ->
        :ok =
          Phoenix.PubSub.broadcast(
            DjRumble.PubSub,
            "room:#{slug}:ready",
            :no_more_rounds
          )

        state

      [{_ref, {_pid, video, 0 = time}} = next_round | next_rounds] ->
        Phoenix.PubSub.subscribe(DjRumble.PubSub, "matchmaking:#{slug}:waiting_for_details")

        :ok = send_playback_details("room:#{slug}:ready", video, time)

        Logger.info(fn -> "Prepared a next round" end)

        %{
          state
          | current_round: next_round,
            next_rounds: next_rounds
        }
    end
  end

  defp send_playback_details(topic, video, time) do
    Phoenix.PubSub.broadcast(
      DjRumble.PubSub,
      topic,
      {:receive_playback_details, %{videoId: video.video_id, time: time}}
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
    {_ref, {pid, _video, _time}} = state.current_round

    # Worths to check if its dead, if not, use the next function
    # RoundSupervisor.terminate_round_server(RoundSupervisor, pid)

    :ok = RoundServer.start_round(pid)

    Phoenix.PubSub.broadcast(
      DjRumble.PubSub,
      "room:#{state.room.slug}:ready",
      {:round_started, RoundServer.get_round(pid)}
    )

    # Process.send_after(self(), :max_series_length_exceeded, @countdown_before_rounds)

    state
  end
end
