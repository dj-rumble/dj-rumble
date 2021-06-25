defmodule DjRumbleWeb.Live.Components.Chat do
  @moduledoc """
  Allow users send and receive messages between them
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Chats.ChatServer

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:new_message, "")}
  end

  @impl true
  def handle_event(
        "new_message",
        %{"submit" => %{"message" => message}},
        socket
      ) do
    socket = socket |> assign(:new_message, nil)

    case String.trim(message) do
      "" ->
        {:noreply, socket}

      _ ->
        %{assigns: assigns} = socket
        %{chat_service: chat_service, user: user} = assigns

        :ok = ChatServer.new_message(chat_service, user, message)

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("typing", _value, %{assigns: _assigns} = socket) do
    {:noreply, socket}
  end

  def handle_event("stop_typing", %{"value" => _message}, socket) do
    {:noreply, socket}
  end

  defp render_prompt(message) do
    ~E"""
      <span class="use-prompt"><%= message %></span>
    """
  end

  defp render_timestamp(timestamp) do
    ~E"""
      <span class="text-sm monospace font-bold <%= timestamp.class %>">
        [<%= timestamp.value %>]
      </span>
    """
  end

  defp render_username(username, class \\ "") do
    ~E"""
      <span class="text-xl font-bold text-gray-300 <%= class %>"><%= username %>:</span>
    """
  end

  defp render_text(message, class \\ "") do
    ~E"""
      <span class="italic text-xl text-gray-300 <%= class %>"><%= message %></span>
    """
  end

  def render_message({:chat_message, message}) do
    ~E"""
      <%= render_timestamp(message.timestamp) %>
      <%= render_prompt(render_username(message.username)) %>
      <%= render_text(message.text) %>
    """
  end
end
