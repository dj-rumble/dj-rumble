defmodule DjRumble.Chats.ChatServer do
  @moduledoc """
  The Chat Server implementation
  """
  use GenServer, restart: :temporary

  require Logger

  def start_link({room_slug}) do
    GenServer.start_link(__MODULE__, {room_slug})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def initial_state(args) do
    %{
      room_slug: args.room_slug
    }
  end

  @impl GenServer
  def init({room_slug}) do
    {:ok, initial_state(%{room_slug: room_slug})}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end
end
