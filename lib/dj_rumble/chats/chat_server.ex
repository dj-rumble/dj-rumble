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

  def new_message(pid, user, message) do
    GenServer.cast(pid, {:new_message, user, message})
  end

  def initial_state(args) do
    %{
      messages: [],
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

  @impl GenServer
  def handle_cast({:new_message, user, message}, state) do
    state = %{state | messages: [state.messages ++ %{user: user, message: message}]}

    {:noreply, state}
  end
end
