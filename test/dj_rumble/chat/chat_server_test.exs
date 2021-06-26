defmodule DjRumble.Chat.ChatServerTest do
  @moduledoc """
  Chat Server tests
  """
  use DjRumble.DataCase
  use DjRumble.TestCase
  use DjRumble.Support.Chats.MessageCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Chats.ChatServer
  alias DjRumbleWeb.Channels

  @default_timezone "America/Buenos_Aires"

  defp generate_user_message(user, message) do
    {user, message}
  end

  defp generate_user_messages(_user, _message, 0) do
    []
  end

  defp generate_user_messages(user, message, n) do
    for _n <- 1..n, do: generate_user_message(user, message)
  end

  def assert_receive_new_user_message(user, message) do
    %DjRumble.Chats.Message.User{
      from: user,
      message: message
    } = create_message([:user_message, message, user, @default_timezone])

    assert_receive(
      {:receive_new_message,
       %DjRumble.Chats.Message.User{
         from: ^user,
         message: ^message
       }}
    )
  end

  def assert_receive_new_user_messages(users_messages) do
    for {user, message} <- users_messages do
      assert_receive_new_user_message(user, message)
    end
  end

  def assert_pid_receive_user_messages(pid, users_messages) do
    assert_receive({:trace, ^pid, :receive, {:receive_messages, received_messages}})

    received_messages =
      Enum.map(
        received_messages,
        fn %DjRumble.Chats.Message.User{from: user, message: message} ->
          {user, message}
        end
      )

    ^users_messages = received_messages
  end

  def assert_pids_receive_user_messages(pids, users_messages) do
    for pid <- pids do
      assert_pid_receive_user_messages(pid, users_messages)
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

    defp do_new_user_message(pid, user, message) do
      :ok = ChatServer.new_message(pid, :user_message, user, message, @default_timezone)
    end

    defp do_new_user_messages(pid, users_messages) do
      for {user, message} <- users_messages do
        :ok = do_new_user_message(pid, user, message)
      end
    end

    defp do_get_messages(pid, from) when is_pid(from) do
      :ok = ChatServer.get_messages(pid, from)
    end

    defp do_get_messages(pid, pids) when is_list(pids) do
      for from <- pids do
        :ok = do_get_messages(pid, from)
      end
    end

    defp test_new_message_is_called(pid, chat_topic, messages_amount) do
      # Setup
      :ok = Channels.subscribe(chat_topic)
      user = user_fixture()
      message = "Hello!"
      users_messages = generate_user_messages(user, message, messages_amount)

      # Exercise
      responses = do_new_user_messages(pid, users_messages)

      # Verify
      ^messages_amount = length(responses)
      assert_receive_new_user_messages(users_messages)

      :ok
    end

    defp test_messages_is_called(pid, messages_amount, times) do
      # Setup
      user = user_fixture()
      message = "Hello!"
      messages_amount = messages_amount
      users_messages = generate_user_messages(user, message, messages_amount)
      _responses = do_new_user_messages(pid, users_messages)
      players_amount = times
      pids_users = spawn_players(players_amount)
      pids = for {pid, _user} <- pids_users, do: pid

      # Exercise
      responses = do_get_messages(pid, pids)

      # Verify
      ^players_amount = length(responses)
      assert_pids_receive_user_messages(pids, users_messages)

      :ok
    end

    test "start_link/1 starts a chat server", %{pid: pid} do
      assert is_pid_alive(pid)
    end

    test "get_state/1 returns a state", %{pid: pid, state: state} do
      assert do_get_state(pid) == state
    end

    test "new_message/1 is called once and returns :ok", %{pid: pid, chat_topic: chat_topic} do
      :ok = test_new_message_is_called(pid, chat_topic, 1)
    end

    test "new_message/1 is called ten times and returns :ok", %{pid: pid, chat_topic: chat_topic} do
      :ok = test_new_message_is_called(pid, chat_topic, 10)
    end

    test "new_message/1 is called a hundred times and returns :ok", %{
      pid: pid,
      chat_topic: chat_topic
    } do
      :ok = test_new_message_is_called(pid, chat_topic, 100)
    end

    test "new_message/1 is called a thousand times and returns :ok", %{
      pid: pid,
      chat_topic: chat_topic
    } do
      :ok = test_new_message_is_called(pid, chat_topic, 1000)
    end

    test "new_message/1 is called ten thousand times and returns :ok", %{
      pid: pid,
      chat_topic: chat_topic
    } do
      :ok = test_new_message_is_called(pid, chat_topic, 10_000)
    end

    test "get_messages/1 is called once with no messages and returns :ok", %{pid: pid} do
      :ok = test_messages_is_called(pid, 0, 1)
    end

    test "get_messages/1 is called once and returns :ok", %{pid: pid} do
      :ok = test_messages_is_called(pid, 100, 1)
    end

    test "get_messages/1 is called ten times and returns :ok", %{pid: pid} do
      :ok = test_messages_is_called(pid, 100, 10)
    end

    test "get_messages/1 is called a hundred times and returns :ok", %{pid: pid} do
      :ok = test_messages_is_called(pid, 100, 100)
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

    defp handle_new_user_message(state, {user, message}) do
      response =
        ChatServer.handle_cast(
          {:new_message, :user_message, user, message, @default_timezone},
          state
        )

      {:noreply, state} = response

      state
    end

    defp handle_new_user_messages(state, users_messages) do
      Enum.reduce(users_messages, {[], state}, fn {user, message}, {messages, state} ->
        {messages ++ [message], handle_new_user_message(state, {user, message})}
      end)
    end

    defp handle_get_messages(state, from) when is_pid(from) do
      response = ChatServer.handle_cast({:get_messages, from}, state)

      {:noreply, ^state} = response

      state
    end

    defp handle_get_messages(state, pids) when is_list(pids) do
      Enum.reduce(pids, state, fn pid, state ->
        handle_get_messages(state, pid)
      end)
    end

    defp assert_has_message(expected_users_messages, {_user, _message} = user_message) do
      assert Enum.member?(expected_users_messages, user_message)
    end

    defp assert_has_messages(state, users_messages) do
      expected_users_messages =
        for %{from: user, message: message} <- state.messages do
          {user, message}
        end

      for user_message <- users_messages do
        assert_has_message(expected_users_messages, user_message)
      end
    end

    defp test_handle_new_message_is_called(state, chat_topic, messages_amount) do
      :ok = Channels.subscribe(chat_topic)
      user = user_fixture()
      message = "Hello!"
      users_messages = generate_user_messages(user, message, messages_amount)

      # Exercise
      {_users_messages, state} = handle_new_user_messages(state, users_messages)

      # Verify
      ^messages_amount = length(state.messages)
      assert_has_messages(state, users_messages)
      assert_receive_new_user_messages(users_messages)

      {:ok, state}
    end

    defp test_handle_get_messages_is_called(state, chat_topic, messages_amount, times) do
      # Setup
      players_amount = times
      pids_users = spawn_players(players_amount)
      pids = for {pid, _user} <- pids_users, do: pid

      {:ok, state} = test_handle_new_message_is_called(state, chat_topic, messages_amount)

      # Exercise
      new_state = handle_get_messages(state, pids)

      # Verify
      assert state.messages == new_state.messages

      users_messages =
        for %{from: user, message: message} <- state.messages do
          {user, message}
        end

      assert_pids_receive_user_messages(pids, users_messages)

      {:ok, new_state}
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
      {:ok, _state} = test_handle_new_message_is_called(state, chat_topic, 1)
    end

    test "handle_cast/2 :: {:new_message, %User{}, message} is called ten times and returns a state with a new messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_new_message_is_called(state, chat_topic, 10)
    end

    test "handle_cast/2 :: {:new_message, %User{}, message} is called a hundred times and returns a state with a new messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_new_message_is_called(state, chat_topic, 100)
    end

    test "handle_cast/2 :: {:new_message, %User{}, message} is called a thousand times and returns a state with a new messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_new_message_is_called(state, chat_topic, 1000)
    end

    test "handle_cast/2 :; {:get_messages, pid} is called once and returns a state with no messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_get_messages_is_called(state, chat_topic, 0, 1)
    end

    test "handle_cast/2 :; {:get_messages, pid} is called once and returns a state with messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_get_messages_is_called(state, chat_topic, 10, 1)
    end

    test "handle_cast/2 :; {:get_messages, pid} is called ten times and returns a state with messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_get_messages_is_called(state, chat_topic, 100, 10)
    end

    test "handle_cast/2 :; {:get_messages, pid} is called a hundred times and returns a state with messages",
         %{chat_topic: chat_topic, state: state} do
      {:ok, _state} = test_handle_get_messages_is_called(state, chat_topic, 100, 100)
    end
  end
end
