defmodule DjRumble.Rooms.RoomSupervisor do
  @moduledoc """
  Specific implementation for the Room Supervisor
  """
  use DynamicSupervisor

  require Logger

  alias DjRumble.Rooms
  alias DjRumble.Rooms.RoomServer

  def start_link(init_arg) do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

    Logger.info(fn -> "RoomSupervisor started with pid: #{inspect(pid)}" end)

    Rooms.list_rooms()
    |> Enum.each(fn room ->
      room = DjRumble.Repo.preload(room, :videos)
      {:ok, _pid} = DynamicSupervisor.start_child(__MODULE__, {RoomServer, {room}})
    end)

    {:ok, pid}
  end

  def start_room_server(supervisor \\ __MODULE__, room) do
    DynamicSupervisor.start_child(supervisor, {RoomServer, {room}})
  end

  def list_room_servers(supervisor \\ __MODULE__) do
    DynamicSupervisor.which_children(supervisor)
    |> Enum.filter(fn
      {_, pid, :worker, _} when is_pid(pid) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, :worker, _} -> pid end)
  end

  def get_room_server(supervisor \\ __MODULE__, id) do
    list_room_servers(supervisor)
    |> Enum.map(&{&1, RoomServer.get_room(&1)})
    |> Enum.find(fn {_, room} -> room.id == id end)
  end

  def terminate_room_server(supervisor \\ __MODULE__, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
