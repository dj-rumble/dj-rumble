defmodule DjRumble.Rooms.RoomSupervisor do
  @moduledoc """
  Specific implementation for the Room Supervisor
  """
  use DynamicSupervisor

  alias DjRumble.Rooms
  alias DjRumble.Rooms.RoomServer

  def start_link(init_arg) do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

    Rooms.list_rooms()
    |> Enum.each(fn room ->
      DynamicSupervisor.start_child(__MODULE__, {RoomServer, {room.id}})
    end)

    {:ok, pid}
  end

  def start_room_server(supervisor \\ __MODULE__, room_id) do
    DynamicSupervisor.start_child(supervisor, {RoomServer, {room_id}})
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
    |> Enum.find(fn {_, room_id} -> room_id == id end)
  end

  def terminate_room_server(supervisor \\ __MODULE__, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
