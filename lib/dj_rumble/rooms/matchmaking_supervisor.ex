defmodule DjRumble.Rooms.MatchmakingSupervisor do
  @moduledoc """
  Specific implementation for the Matchmaking Supervisor
  """
  use DynamicSupervisor

  alias DjRumble.Rooms.Matchmaking

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_matchmaking_server(supervisor, room) do
    DynamicSupervisor.start_child(supervisor, {Matchmaking, {room}})
  end

  def list_matchmaking_servers(supervisor \\ __MODULE__) do
    DynamicSupervisor.which_children(supervisor)
    |> Enum.filter(fn
      {_, pid, :worker, _} when is_pid(pid) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, :worker, _} -> pid end)
  end

  def get_matchmaking_server(supervisor, slug) do
    list_matchmaking_servers(supervisor)
    |> Enum.map(&{&1, Matchmaking.get_state(&1)})
    |> Enum.find(fn {_, state} -> state.room.slug == slug end)
  end

  def terminate_matchmaking_server(supervisor, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
