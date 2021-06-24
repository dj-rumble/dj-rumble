defmodule DjRumble.Chats.ChatSupervisor do
  @moduledoc """
  Specific implementation for the Chat Supervisor
  """
  use DynamicSupervisor

  alias DjRumble.Chats.ChatServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_server(supervisor, {room_slug}) do
    DynamicSupervisor.start_child(supervisor, {ChatServer, {room_slug}})
  end

  def list_servers(supervisor \\ __MODULE__) do
    DynamicSupervisor.which_children(supervisor)
    |> Enum.filter(fn
      {_, pid, :worker, _} when is_pid(pid) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, :worker, _} -> pid end)
  end

  def get_server(supervisor, slug) do
    list_servers(supervisor)
    |> Enum.map(&{&1, ChatServer.get_state(&1)})
    |> Enum.find(fn {_, state} -> state.room_slug == slug end)
  end

  def terminate_server(supervisor, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
