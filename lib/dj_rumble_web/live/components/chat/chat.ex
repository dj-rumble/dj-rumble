defmodule DjRumbleWeb.Live.Components.Chat do
  @moduledoc """
  Allow users send and receive messages between them
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.Chat

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
    socket = socket |> assign(:new_message, "")

    case String.trim(message) do
      "" ->
        {:noreply, socket}

      _ ->
        %{assigns: assigns} = socket
        %{messages: messages, room: room, username: username} = assigns
        new_message = %{message: message, username: username}
        message = Chat.create_message(:chat_message, new_message)
        messages = messages ++ [message]

        Phoenix.PubSub.broadcast(
          DjRumble.PubSub,
          "room:" <> room.slug,
          {:receive_messages, %{messages: messages}}
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("typing", _value, %{assigns: assigns} = socket) do
    %{room: room} = assigns
    # Chat.start_typing(slug, uuid)
    {:noreply, socket}
  end

  def handle_event("stop_typing", %{"value" => message}, socket) do
    %{assigns: %{room: room}} = socket
    # Chat.stop_typing(slug, uuid)
    {:noreply, assign(socket, new_message: message)}
  end

  defp render_prompt(message) do
    ~E"""
      <span class="use-prompt"><%= message %></span>
    """
  end

  defp render_timestamp(timestamp) do
    ~E"""
      <span class="timestamp <%= timestamp.class %>">
        [<%= timestamp.value %>]
      </span>
    """
  end

  defp render_username(username, class \\ "") do
    ~E"""
      <span class="chat-username <%= class %>"><%= username %>:</span>
    """
  end

  defp render_text(message, class \\ "") do
    ~E"""
      <span class="chat-text <%= class %>"><%= message %></span>
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