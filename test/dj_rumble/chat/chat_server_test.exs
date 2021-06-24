defmodule DjRumble.Chat.ChatServerTest do
  @moduledoc """
  Chat Server tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  alias DjRumble.Chats.ChatServer

  describe "chat_server client interface" do
    setup do
      %{slug: room_slug} = _room = room_fixture()

      chat_server_pid = start_supervised!({ChatServer, {room_slug}})

      initial_state = ChatServer.initial_state(%{room_slug: room_slug})

      %{pid: chat_server_pid, room_slug: room_slug, state: initial_state}
    end

    defp is_pid_alive(pid) do
      is_pid(pid) and Process.alive?(pid)
    end

    test "start_link/1 starts a chat server", %{pid: pid} do
      assert is_pid_alive(pid)
    end

    test "get_state/1 returns a state", %{pid: pid, state: state} do
      assert ChatServer.get_state(pid) == state
    end
  end

  describe "room_server server implementation" do
    setup do
      %{slug: room_slug} = _room = room_fixture()

      initial_state = ChatServer.initial_state(%{room_slug: room_slug})

      %{state: initial_state}
    end

    def handle_get_state(state) do
      response = ChatServer.handle_call(:get_state, nil, state)

      {:reply, ^state, ^state} = response

      state
    end

    test "handle_call/3 :: :get_state replies with an unmodified state", %{state: state} do
      # Exercise & Verify
      ^state = handle_get_state(state)
    end
  end
end
