defmodule DjRumble.Rooms.RoomServer do
  @moduledoc """
  The Room Server implementation
  """
  use GenServer, restart: :transient

  require Logger

  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor}

  def start_link({_room} = init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def start_round(pid) do
    GenServer.call(pid, :start_round)
  end

  def get_room(pid) do
    GenServer.call(pid, :get_room)
  end

  def join(pid) do
    GenServer.call(pid, :join)
  end

  def get_narration(pid) do
    GenServer.call(pid, :get_narration)
  end

  @impl GenServer
  def init({room} = init_arg) do
    Logger.info(fn ->
      "RoomServer started with pid: #{inspect(self())} and state: #{inspect(init_arg)}"
    end)

    {:ok, matchmaking_server} =
      MatchmakingSupervisor.start_matchmaking_server(MatchmakingSupervisor, room)

    Enum.each(room.videos, fn video ->
      :ok = Matchmaking.create_round(matchmaking_server, video)
    end)

    state = %{
      matchmaking_server: matchmaking_server,
      players: %{},
      room: room,
      current_video: nil,
      previous_videos: [],
      next_videos: room.videos
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:start_round, _from, state) do
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:get_room, _from, state) do
    {:reply, state.room, state}
  end

  @impl GenServer
  def handle_call(:join, {pid, _ref}, state) do
    ref = Process.monitor(pid)

    Logger.info(fn -> "Player with pid: #{inspect(pid)} just joined the room." end)

    state = %{
      state
      | players: Map.put(state.players, ref, {pid})
    }

    {:reply, :ok, state, {:continue, {:joined, pid}}}
  end

  @impl GenServer
  def handle_continue({:joined, pid}, state) do
    case Map.to_list(state.players) do
      [_p] ->
        :ok = Matchmaking.start_round(state.matchmaking_server)

      [_p | _ps] ->
        nil
    end

    Process.send(pid, {:welcome, "Hello #{inspect(pid)}!!"}, [])
    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state = %{
      state
      | players: Map.delete(state.players, ref)
    }

    {:noreply, state}
  end
end
