defmodule DjRumble.Chats.ChatServer do
  @moduledoc """
  The Chat Server implementation
  """
  use GenServer, restart: :temporary

  require Logger

  alias DjRumble.Chats.Message
  alias DjRumbleWeb.Channels

  def start_link({chat_topic}) do
    GenServer.start_link(__MODULE__, {chat_topic})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def get_messages(pid, from) do
    GenServer.cast(pid, {:get_messages, from})
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
  def handle_cast({:get_messages, from}, %{messages: messages} = state) do
    :ok = Process.send(from, {:receive_messages, messages}, [])
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast({:new_message, user, message}, state) do
    message = Message.create_message(message, user)
    state = %{state | messages: state.messages ++ [message]}

    :ok = Channels.broadcast(state.chat_topic, {:receive_new_message, message})

    {:noreply, state}
  end
end
