defmodule DjRumble.Chats.Supervisor do
  @moduledoc """
  Generic implementation for the Chat Supervisor
  """
  use Supervisor

  alias DjRumble.Chats

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      Chats.ChatSupervisor
    ]

    Supervisor.start_link(children, strategy: :rest_for_one)
  end
end
