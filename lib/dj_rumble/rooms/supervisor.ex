defmodule DjRumble.Rooms.Supervisor do
  @moduledoc """
  Generic implementation for the Room Supervisor
  """
  use Supervisor

  alias DjRumble.Rooms.{MatchmakingSupervisor, RoomSupervisor}

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      MatchmakingSupervisor,
      RoomSupervisor
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end
end
