defmodule DjRumble.Rounds.RoundServer do
  @moduledoc """
  The Round Server implementation
  """
  use GenServer, restart: :temporary

  require Logger

  alias DjRumble.Rounds.Round

  alias DjRumbleWeb.Channels

  @seconds_per_tick 1

  def start_link({room_slug}) do
    GenServer.start_link(__MODULE__, {room_slug})
  end

  def start_round(pid) do
    GenServer.call(pid, :start_round)
  end

  def get_room_slug(pid) do
    GenServer.call(pid, :get_room_slug)
  end

  def get_round(pid) do
    GenServer.call(pid, :get_round)
  end

  def get_narration(pid) do
    GenServer.call(pid, :get_narration)
  end

  def set_round_time(pid, time) do
    GenServer.call(pid, {:set_round_time, time})
  end

  def score(pid, user, type) do
    GenServer.call(pid, {:score, user, type})
  end

  def initial_state(args) do
    %{
      room_slug: args.room_slug,
      round: args.round,
      voters: Map.new()
    }
  end

  @impl GenServer
  def init({room_slug}) do
    {:ok, initial_state(%{room_slug: room_slug, round: Round.schedule(0)})}
  end

  @impl GenServer
  def handle_call(:start_round, _from, %{round: round} = state) do
    schedule_next_tick()

    {:reply, :ok, %{state | round: Round.start(round)}}
  end

  @impl GenServer
  def handle_call(:get_room_slug, _from, %{room_slug: room_slug} = state) do
    {:reply, room_slug, state}
  end

  @impl GenServer
  def handle_call(:get_round, _from, %{round: round} = state) do
    {:reply, round, state}
  end

  @impl GenServer
  def handle_call(:get_narration, _from, %{round: %Round.InProgress{} = round} = state) do
    {:reply, Round.narrate(round), state}
  end

  @impl GenServer
  def handle_call(:get_narration, _from, %{round: %Round.Finished{} = round} = state) do
    {:reply, Round.narrate(round), state}
  end

  @impl GenServer
  def handle_call(
        {:set_round_time, time},
        _from,
        %{round: %Round.Scheduled{} = round} = state
      ) do
    {:reply, :ok, %{state | round: Round.set_time(round, time)}}
  end

  @impl GenServer
  def handle_call({:score, user, type}, _from, %{round: %Round.InProgress{} = round} = state) do
    %{voters: voters} = state

    state =
      case Map.get(voters, user.id) do
        nil ->
          round = Round.set_score(round, type)
          voters = Map.put(voters, user.id, type)

          %{state | round: round, voters: voters}

        _vote ->
          state
      end

    {:reply, state.round, state}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    %{room_slug: room_slug, round: %Round.InProgress{outcome: outcome} = round} = state

    case Round.simulate_tick(round) do
      %Round.InProgress{outcome: ^outcome} = round ->
        schedule_next_tick()
        {:noreply, %{state | round: round}}

      %Round.InProgress{} = round ->
        :ok = Channels.broadcast(:room, room_slug, {:outcome_changed, %{round: round}})
        schedule_next_tick()
        {:noreply, %{state | round: round}}

      %Round.Finished{} = round ->
        {:stop, {:shutdown, round}, %{state | round: round}}
    end
  end

  defp schedule_next_tick do
    Process.send_after(self(), :tick, @seconds_per_tick * 1000)
  end
end
