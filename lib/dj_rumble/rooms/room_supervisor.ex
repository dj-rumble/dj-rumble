defmodule DjRumble.Rooms.RoomSupervisor do
  @moduledoc """
  Specific implementation for the Room Supervisor
  """
  use DynamicSupervisor

  require Logger

  alias DjRumble.Chats.ChatSupervisor
  alias DjRumble.Rooms
  alias DjRumble.Rooms.RoomServer

  def start_link(init_arg) do
    {:ok, pid} = DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

    Logger.info(fn -> "RoomSupervisor started with pid: #{inspect(pid)}" end)

    :ok =
      Rooms.list_rooms()
      |> Enum.each(fn room ->
        {:ok, _pid} = start_room_server(__MODULE__, room)
      end)

    {:ok, pid}
  end

  def start_room_server(supervisor, room) do
    room = Rooms.preload_room(room, users_rooms_videos: [:video, :user])

    {:ok, chat_server} = ChatSupervisor.start_server(ChatSupervisor, {room.slug})

    DynamicSupervisor.start_child(supervisor, {RoomServer, {room, chat_server}})
  end

  def list_room_servers(supervisor \\ __MODULE__) do
    DynamicSupervisor.which_children(supervisor)
    |> Enum.filter(fn
      {_, pid, :worker, _} when is_pid(pid) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, :worker, _} -> pid end)
  end

  def get_room_server(supervisor, slug) do
    list_room_servers(supervisor)
    |> Enum.map(&{&1, RoomServer.get_state(&1)})
    |> Enum.find(fn {_, state} -> state.room.slug == slug end)
  end

  def terminate_room_server(supervisor, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
