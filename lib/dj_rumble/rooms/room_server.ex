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

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def join(pid) do
    GenServer.call(pid, :join)
  end

  def get_narration(pid) do
    GenServer.call(pid, :get_narration)
  end

  def list_next_rounds(matchmaking_server) do
    Matchmaking.list_next_rounds(matchmaking_server)
  end

  def get_current_round(matchmaking_server) do
    Matchmaking.get_current_round(matchmaking_server)
  end

  def create_round(matchmaking_server, video) do
    Matchmaking.create_round(matchmaking_server, video)
  end

  @impl GenServer
  def init({room} = _init_arg) do
    Logger.info(fn ->
      "RoomServer started with pid: #{inspect(self())} for room: #{room.slug}"
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
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
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
    Process.send(pid, {:welcome, "Hello!"}, [])

    players_list = Map.to_list(state.players)

    Logger.info(fn -> "Current players: #{length(players_list)}." end)

    case players_list do
      [_p] ->
        :ok = Matchmaking.start_round(state.matchmaking_server)

      [_p | _ps] ->
        :ok = Matchmaking.join(state.matchmaking_server, pid)
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    state = %{
      state
      | players: Map.delete(state.players, ref)
    }

    Logger.info(fn -> "A player left. Current players: #{length(Map.to_list(state.players))}." end)

    {:noreply, state}
  end
end
