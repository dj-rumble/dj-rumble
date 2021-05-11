defmodule DjRumble.Rounds.RoundServer do
  @moduledoc """
  The Round Server implementation
  """
  use GenServer, restart: :temporary

  alias DjRumble.Rounds.Round

  @seconds_per_tick 1

  @doc """
  Round Server client interface
  """

  def start_link({room_id, round_time}) do
    GenServer.start_link(__MODULE__, {room_id, round_time})
  end

  def start_round(pid) do
    GenServer.call(pid, :start_round)
  end

  def get_room(pid) do
    GenServer.call(pid, :get_room)
  end

  def get_round(pid) do
    GenServer.call(pid, :get_round)
  end

  def get_narration(pid) do
    GenServer.call(pid, :get_narration)
  end

  @doc """
  Round Server implementation
  """

  @impl GenServer
  def init({room_id, round_time}) do
    {:ok, {room_id, Round.schedule(round_time)}}
  end

  @impl GenServer
  def handle_call(:start_round, _from, {room_id, %Round.Scheduled{} = round}) do
    schedule_next_tick()

    {:reply, :ok, {room_id, Round.start(round)}}
  end

  @impl GenServer
  def handle_call(:get_room, _from, {room_id, _round} = state) do
    {:reply, room_id, state}
  end

  @impl GenServer
  def handle_call(:get_round, _from, {_room_id, round} = state) do
    {:reply, round, state}
  end

  @impl GenServer
  def handle_call(:get_narration, _from, {_room_id, %Round.InProgress{} = round} = state) do
    {:reply, Round.narrate(round), state}
  end

  @impl GenServer
  def handle_call(:get_narration, _from, {_room_id, %Round.Finished{} = round} = state) do
    {:reply, Round.narrate(round), state}
  end

  @impl GenServer
  def handle_info(:tick, {room_id, %Round.InProgress{} = round} = _state) do
    case Round.simulate_tick(round) do
      %Round.InProgress{} = round ->
        schedule_next_tick()
        {:noreply, {room_id, round}}

      %Round.Finished{} = round ->
        # {:noreply, {room_id, round}}
        {:stop, {:shutdown, round}, {room_id, round}}
    end
  end

  defp schedule_next_tick do
    Process.send_after(self(), :tick, @seconds_per_tick * 1000)
  end
end
