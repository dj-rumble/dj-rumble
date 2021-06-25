defmodule DjRumble.Chats.ChatServer do
  @moduledoc """
  The Chat Server implementation
  """
  use GenServer, restart: :temporary

  require Logger

  alias DjRumbleWeb.Channels

  def start_link({chat_topic}) do
    GenServer.start_link(__MODULE__, {chat_topic})
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
      chat_topic: args.chat_topic
    }
  end

  @impl GenServer
  def init({chat_topic}) do
    {:ok, initial_state(%{chat_topic: chat_topic})}
  end

  @impl GenServer
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_cast({:new_message, user, message}, state) do
    user_message = %{user: user, message: message}
    state = %{state | messages: state.messages ++ [user_message]}

    :ok = Channels.broadcast(state.chat_topic, {:receive_chat_message, user_message})

    {:noreply, state}
  end
end
