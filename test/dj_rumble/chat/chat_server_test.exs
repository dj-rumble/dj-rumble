defmodule DjRumble.Chat.ChatServerTest do
  @moduledoc """
  Chat Server tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Chats.ChatServer
  alias DjRumbleWeb.Channels

  defp generate_message(user, message) do
    {user, message}
  end

  defp generate_messages(user, message, n) do
    for _n <- 1..n, do: generate_message(user, message)
  end

  def assert_receive_message(user_message) do
    assert_receive({:receive_chat_message, ^user_message})
  end

  def assert_receive_messages(users_messages) do
    for {user, message} <- users_messages do
      assert_receive_message(%{user: user, message: message})
    end
  end

  describe "chat_server client interface" do
    setup do
      %{slug: room_slug} = _room = room_fixture()

      chat_topic = Channels.get_topic(:room_chat, room_slug)
      chat_server_pid = start_supervised!({ChatServer, {chat_topic}})

      initial_state = ChatServer.initial_state(%{chat_topic: chat_topic})

      %{pid: chat_server_pid, chat_topic: chat_topic, state: initial_state}
    end

    defp do_get_state(pid) do
      ChatServer.get_state(pid)
    end

    defp do_new_message(pid, user, message) do
      :ok = ChatServer.new_message(pid, user, message)
    end

    defp do_new_messages(pid, users_messages) do
      for {user, message} <- users_messages do
        :ok = do_new_message(pid, user, message)
      end
    end

    defp is_pid_alive(pid) do
      is_pid(pid) and Process.alive?(pid)
    end

    test "start_link/1 starts a chat server", %{pid: pid} do
      assert is_pid_alive(pid)
    end

    test "get_state/1 returns a state", %{pid: pid, state: state} do
      assert do_get_state(pid) == state
    end

    test "new_message/1 is called once and returns :ok", %{pid: pid, chat_topic: chat_topic} do
      # Setup
      :ok = Channels.subscribe(chat_topic)
      user = user_fixture()
      message = "Hello!"
      messages_amount = 1
      users_messages = generate_messages(user, message, messages_amount)

      # Exercise
      responses = do_new_messages(pid, users_messages)

      # Verify
      ^messages_amount = length(responses)
      assert_receive_messages(users_messages)
    end

    test "new_message/1 is called many times and returns :ok", %{pid: pid, chat_topic: chat_topic} do
      # Setup
      :ok = Channels.subscribe(chat_topic)
      user = user_fixture()
      message = "Hello!"
      messages_amount = 10
      users_messages = generate_messages(user, message, messages_amount)

      # Exercise
      responses = do_new_messages(pid, users_messages)

      # Verify
      ^messages_amount = length(responses)
      assert_receive_messages(users_messages)
    end
  end

  describe "room_server server implementation" do
    setup do
      %{slug: room_slug} = _room = room_fixture()

      chat_topic = Channels.get_topic(:room_chat, room_slug)
      initial_state = ChatServer.initial_state(%{chat_topic: chat_topic})

      %{state: initial_state, chat_topic: chat_topic}
    end

    defp handle_get_state(state) do
      response = ChatServer.handle_call(:get_state, nil, state)

      {:reply, ^state, ^state} = response

      state
    end

    defp handle_new_message(state, {user, message}) do
      response = ChatServer.handle_cast({:new_message, user, message}, state)

      {:noreply, state} = response

      state
    end

    defp handle_new_messages(state, users_messages) do
      Enum.reduce(users_messages, {[], state}, fn {user, message}, {messages, state} ->
        {messages ++ [message], handle_new_message(state, {user, message})}
      end)
    end

    defp assert_has_message(expected_users_messages, {_user, _message} = user_message) do
      assert Enum.member?(expected_users_messages, user_message)
    end

    defp assert_has_messages(state, users_messages) do
      expected_users_messages =
        for %{user: user, message: message} <- state.messages do
          {user, message}
        end

      for user_message <- users_messages do
        assert_has_message(expected_users_messages, user_message)
      end
    end

    test "chat_server has an initial state", %{chat_topic: chat_topic, state: state} do
      %{messages: [], chat_topic: ^chat_topic} = state
    end

    test "handle_call/3 :: :get_state replies with an unmodified state", %{state: state} do
      # Exercise & Verify
      ^state = handle_get_state(state)
    end

    test "handle_cast/2 :: {:new_message, %User{}, message} is called once and returns a state with a new message",
         %{chat_topic: chat_topic, state: state} do
      :ok = Channels.subscribe(chat_topic)
      user = user_fixture()
      message = "Hello!"
      messages_amount = 1
      users_messages = generate_messages(user, message, messages_amount)

      # Exercise
      {_users_messages, state} = handle_new_messages(state, users_messages)

      # Verify
      ^messages_amount = length(state.messages)
      assert_has_messages(state, users_messages)
      assert_receive_messages(users_messages)
    end

    @tag :wip
    test "handle_cast/2 :: {:new_message, %User{}, message} is called many times and returns a state with a new messages",
         %{chat_topic: chat_topic, state: state} do
      :ok = Channels.subscribe(chat_topic)
      user = user_fixture()
      message = "Hello!"
      messages_amount = 10
      users_messages = generate_messages(user, message, messages_amount)

      # Exercise
      {_users_messages, state} = handle_new_messages(state, users_messages)

      # Verify
      ^messages_amount = length(state.messages)
      assert_has_messages(state, users_messages)
      assert_receive_messages(users_messages)
    end
  end
end
