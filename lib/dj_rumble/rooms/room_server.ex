defmodule DjRumble.Rooms.RoomServer do
  @moduledoc """
  The Room Server implementation
  """
  use GenServer, restart: :transient

  require Logger

  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor}

  alias DjRumbleWeb.Channels

  def start_link({_room} = init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def join(pid) do
    GenServer.call(pid, :join)
  end

  def list_next_rounds(matchmaking_server) do
    Matchmaking.list_next_rounds(matchmaking_server)
  end

  def get_current_round(matchmaking_server) do
    Matchmaking.get_current_round(matchmaking_server)
  end

  def create_round(matchmaking_server, video, user) do
    Matchmaking.create_round(matchmaking_server, video, user)
  end

  def score(pid, from, type) do
    GenServer.cast(pid, {:score, from, type})
  end

  def initial_state(args) do
    %{
      matchmaking_server: args.matchmaking_server,
      players: %{},
      room: args.room
    }
  end

  @impl GenServer
  def init({room} = _init_arg) do
    # coveralls-ignore-start
    Logger.info(fn ->
      "RoomServer started with pid: #{inspect(self())} for room: #{room.slug}"
    end)

    # coveralls-ignore-stop

    {:ok, matchmaking_server} =
      MatchmakingSupervisor.start_matchmaking_server(MatchmakingSupervisor, room)

    :ok =
      Enum.map(room.users_rooms_videos, &{&1.video, &1.user})
      |> Enum.each(fn {video, user} ->
        :ok = Matchmaking.create_round(matchmaking_server, video, user)
      end)

    state = initial_state(%{matchmaking_server: matchmaking_server, room: room})

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

    :ok = Matchmaking.join(state.matchmaking_server, pid)

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:score, _from, type}, state) do
    %{matchmaking_server: matchmaking_server} = state

    round = Matchmaking.score(matchmaking_server, type)

    :ok =
      Channels.broadcast(:room, state.room.slug, {:receive_score, %{type: type, round: round}})

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
