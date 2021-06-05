defmodule DjRumble.Rounds.Supervisor do
  @moduledoc """
  Generic implementation for the Round Supervisor
  """
  use Supervisor

  alias DjRumble.Rounds

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Rounds.RoundSupervisor
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end
end
