defmodule DjRumbleWeb.Live.Components.Chat do
  @moduledoc """
  Allow users send and receive messages between them
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Chats.Message
  alias DjRumble.Rooms.RoomServer

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
        %{room_service: room_service, timezone: timezone, user: user} = assigns

        :ok = RoomServer.new_message(room_service, user, message, timezone)

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
    highlight_style =
      case timestamp =~ "04:20:" || timestamp =~ "16:20:" do
        true -> "text-green-400"
        false -> "text-blue-500"
      end

    ~E"""
      <span class="text-sm monospace font-bold <%= highlight_style %>">
        [<%= timestamp %>]
      </span>
    """
  end

  defp render_username(username) do
    ~E"""
      <span class="text-xl font-bold text-gray-300"><%= username %>:</span>
    """
  end

  defp render_text(message) do
    ~E"""
      <span class="italic text-xl text-gray-300"><%= message %></span>
    """
  end

  def render_message(%Message.User{from: user, message: message, timestamp: timestamp}) do
    ~E"""
      <%= render_timestamp(timestamp) %>
      <%= render_prompt(render_username(user.username)) %>
      <%= render_text(message) %>
    """
  end
end
