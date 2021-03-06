defmodule DjRumble.Chat.ChatSupervisorTest do
  @moduledoc """
  Room Supervisor tests
  """
  use DjRumble.DataCase
  use ExUnit.Case

  import DjRumble.RoomsFixtures

  # The ChatSupervisor pid is automatically started on tests run since it's part
  # of the djrumble main application process.
  describe "chat_supervisor" do
    alias DjRumble.Chats.ChatSupervisor
    alias DjRumbleWeb.Channels

    setup do
      %{slug: slug} = _room = room_fixture()

      chat_topic = Channels.get_topic(:room_chat, slug)
      {:ok, pid} = ChatSupervisor.start_server(ChatSupervisor, {chat_topic})

      on_exit(fn -> ChatSupervisor.terminate_server(ChatSupervisor, pid) end)

      {^pid, state} = ChatSupervisor.get_server(ChatSupervisor, chat_topic)

      %{pid: pid, chat_topic: chat_topic, state: state}
    end

    test "start_room_server/2 starts a chat server", %{pid: pid} do
      assert is_pid(pid)
      assert Process.alive?(pid)
    end

    test "list_servers/1 returns a list of chat server pids", %{pid: pid} do
      assert Enum.member?(ChatSupervisor.list_servers(), pid)
    end

    test "get_server/2 returns a chat server pid and state", %{
      chat_topic: chat_topic,
      pid: pid,
      state: state
    } do
      {^pid, ^state} = ChatSupervisor.get_server(ChatSupervisor, chat_topic)
      assert Process.alive?(pid)
    end

    test "terminate_server/2 shuts down a chat server process", %{pid: pid} do
      assert Process.alive?(pid)
      :ok = ChatSupervisor.terminate_server(ChatSupervisor, pid)
      refute Process.alive?(pid)
    end
  end
end
