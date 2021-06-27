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

  defp render_prompt(symbol, classes) do
    ~E"""
    <span class="<%= classes %>"><%= symbol %></span>
    """
  end

  defp render_timestamp(timestamp) do
    highlight_style =
      case timestamp =~ "04:20:" || timestamp =~ "16:20:" do
        true -> "text-green-400"
        false -> "text-gray-600"
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

  defp render_text(message, extra_classes \\ "") do
    ~E"""
    <span class="italic text-xl text-gray-300 <%= extra_classes %>"><%= message %></span>
    """
  end

  def render_message(%Message.User{from: user, message: message, timestamp: timestamp}) do
    ~E"""
    <p class="mb-0.5 text-lg text-left animated fadeIn px-2">
      <%= render_timestamp(timestamp) %>
      <%= render_username(user.username) %>
      <%= render_text(message) %>
    </p>
    """
  end

  def render_message(%Message.Video{} = message) do
    message = narrate_message(Message.narrate(message))

    ~E"""
    <p class="
      mb-0.5 my-2 py-4 px-2
      border-t-2 border-gray-900 border-opacity-5
      text-lg not-italic font-normal text-left
      animated fadeIn
    ">
    <%= render_prompt(">", "text-gray-300") %>
    <%= message %>
    </p>
    """
  end

  def render_message(%Message.Score{} = message) do
    message = narrate_message(Message.narrate(message))

    ~E"""
    <p class="
      mb-0.5 my-2 py-4 px-2
      border-t-2 border-gray-900 border-opacity-5
      text-lg not-italic font-normal text-left
      animated fadeIn
    ">
    <%= render_prompt(">", "text-gray-300") %>
    <%= message %>
    </p>
    """
  end

  defp narrate_message(message_chunks) do
    Enum.map(message_chunks, fn chunk ->
      {text, classes} = get_styles_maybe(chunk)
      render_text(text, classes)
    end)
  end

  defp get_styles_maybe({type, text}), do: {text, get_style_by_type(type)}
  defp get_styles_maybe(text), do: {text, ""}

  defp get_style_by_type(:args), do: "text-blue-500"
  defp get_style_by_type(:username), do: "not-italic font-bold"
  defp get_style_by_type(:video), do: "text-pink-500"
  defp get_style_by_type(_), do: ""
end
