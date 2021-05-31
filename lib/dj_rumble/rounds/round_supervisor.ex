defmodule DjRumble.Rounds.RoundSupervisor do
  @moduledoc """
  Specific implementation for the Round Supervisor
  """
  use DynamicSupervisor

  alias DjRumble.Rounds.RoundServer

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_round_server(supervisor, {room_slug, round_time}) do
    DynamicSupervisor.start_child(supervisor, {RoundServer, {room_slug, round_time}})
  end

  def list_round_servers(supervisor \\ __MODULE__) do
    DynamicSupervisor.which_children(supervisor)
    |> Enum.filter(fn
      {_, pid, :worker, _} when is_pid(pid) -> true
      _ -> false
    end)
    |> Enum.map(fn {_, pid, :worker, _} -> pid end)
  end

  def get_round_server(supervisor, slug) do
    list_round_servers(supervisor)
    |> Enum.map(&{&1, RoundServer.get_room_slug(&1)})
    |> Enum.find(fn {_, room_slug} -> room_slug == slug end)
  end

  def terminate_round_server(supervisor, pid) do
    DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
