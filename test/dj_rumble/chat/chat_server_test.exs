defmodule DjRumble.Chat.ChatServerTest do
  @moduledoc """
  Chat Server tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.AccountsFixtures
  import DjRumble.RoomsFixtures

  alias DjRumble.Chats.ChatServer

  defp generate_message(user, message) do
    {user, message}
  end

  defp generate_messages(user, message, n) do
    for _n <- 1..n, do: generate_message(user, message)
  end

  describe "chat_server client interface" do
    setup do
      %{slug: room_slug} = _room = room_fixture()

      chat_server_pid = start_supervised!({ChatServer, {room_slug}})

      initial_state = ChatServer.initial_state(%{room_slug: room_slug})

      %{pid: chat_server_pid, room_slug: room_slug, state: initial_state}
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

    test "new_message/1 is called once and returns :ok", %{pid: pid} do
      # Setup
      user = user_fixture()
      message = "Hello!"

      # Exercise & Verify
      :ok = do_new_message(pid, user, message)
    end

    test "new_message/1 is called many times and returns :ok", %{pid: pid} do
      # Setup
      user = user_fixture()
      message = "Hello!"
      messages_amount = 10
      users_messages = generate_messages(user, message, messages_amount)

      # Exercise & Verify
      responses = do_new_messages(pid, users_messages)
      ^messages_amount = length(responses)
    end
  end

  describe "room_server server implementation" do
    setup do
      %{slug: room_slug} = _room = room_fixture()

      initial_state = ChatServer.initial_state(%{room_slug: room_slug})

      %{state: initial_state, room_slug: room_slug}
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

    test "chat_server has an initial state", %{room_slug: room_slug, state: state} do
      %{messages: [], room_slug: ^room_slug} = state
    end

    test "handle_call/3 :: :get_state replies with an unmodified state", %{state: state} do
      # Exercise & Verify
      ^state = handle_get_state(state)
    end

    test "handle_cast/2 :: {:new_message, %User{}, message} is called once and returns a state with a new message",
         %{state: state} do
      user = user_fixture()
      message = "Hello!"
      users_messages = generate_messages(user, message, 1)

      # Exercise
      {_users_messages, state} = handle_new_messages(state, users_messages)

      # Verify
      assert_has_messages(state, users_messages)
    end
  end
end
