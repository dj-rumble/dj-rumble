defmodule DjRumble.Rooms.RoomServer do
  @moduledoc """
  The Room Server implementation
  """
  use GenServer, restart: :temporary

  def start_link({_room_id} = init_arg) do
    GenServer.start_link(__MODULE__, init_arg)
  end

  def start_round(pid) do
    GenServer.call(pid, :start_round)
  end

  def get_room(pid) do
    GenServer.call(pid, :get_room)
  end

  def get_narration(pid) do
    GenServer.call(pid, :get_narration)
  end

  @impl GenServer
  def init({room_id}) do
    # round_server_pid = Round
    {:ok, {room_id}}
  end

  @impl GenServer
  def handle_call(:start_round, _from, {room_id}) do
    {:reply, :ok, {room_id}}
  end

  @impl GenServer
  def handle_call(:get_room, _from, {room_id}) do
    {:reply, room_id, {room_id}}
  end

  @impl GenServer
  def handle_call(:get_narration, _from, {room_id}) do
    {:reply, room_id, {room_id}}
  end
end
