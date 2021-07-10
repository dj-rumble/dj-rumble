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
    <span class="text-lg monospace font-bold <%= highlight_style %>">
      [<%= timestamp %>]
    </span>
    """
  end

  defp render_username(username) do
    ~E"""
    <span class="text-2xl font-bold text-gray-300"><%= username %>:</span>
    """
  end

  defp render_text(message, extra_classes \\ "") do
    ~E"""
    <span class="italic text-2xl text-gray-300 <%= extra_classes %>"><%= message %></span>
    """
  end

  def render_message(%Message.User{from: user, message: message, timestamp: timestamp}) do
    ~E"""
    <p class="mb-0.5 text-2xl text-left animated fadeIn px-2">
      <%= render_timestamp(timestamp) %>
      <%= render_username(user.username) %>
      <%= render_text(message) %>
    </p>
    """
  end

  def render_message(%Message.Video{action: :finished = action, narration: narration}) do
    container_classes = get_classes_by_action(action)

    ~E"""
    <p class="
      mb-0.5 my-2 pt-6 px-2
      border-t-2 border-gray-900 border-opacity-5
      font-normal text-left
      animated fadeIn <%= container_classes %>
    ">
    <%= render_prompt(">", "text-xl text-gray-300") %>
    <%= narrate_message(narration, "not-italic") %>
    </p>
    """
  end

  def render_message(%Message.Video{action: action} = message) do
    message_classes = get_classes_by_action(action)

    ~E"""
    <p class="
      mb-0.5 my-2 pt-6 px-2
      border-t-2 border-gray-900 border-opacity-5
      font-normal text-left
      animated fadeIn
    ">
    <%= render_prompt(">", "text-xl text-gray-300") %>
    <%= narrate_message(Message.narrate(message), "not-italic #{message_classes}") %>
    </p>
    """
  end

  def render_message(%Message.Score{narration: narration}) do
    ~E"""
    <p class="
      mb-0.5 my-2 py-2 px-2
      not-italic font-normal text-left
      animated fadeIn
    ">
    <%= narrate_message(narration, "font-md text-gray-400") %>
    </p>
    """
  end

  defp narrate_message(message_chunks, extra_classes) do
    Enum.map(message_chunks, fn chunk ->
      {text, classes} = get_styles_maybe(chunk)
      render_text(text, "#{extra_classes} #{classes}")
    end)
  end

  defp get_classes_by_action(:playing), do: "animate-pulse"
  defp get_classes_by_action(:finished), do: ""
  defp get_classes_by_action(_), do: ""

  defp get_styles_maybe({type, text}), do: {text, get_style_by_type(type)}
  defp get_styles_maybe(text), do: {text, ""}

  defp get_style_by_type(:args), do: "text-blue-500"
  defp get_style_by_type(:positive_score), do: "text-green-700"
  defp get_style_by_type(:negative_score), do: "text-red-800"
  defp get_style_by_type(:username), do: "not-italic font-bold"
  defp get_style_by_type(:video), do: "text-pink-400"
  defp get_style_by_type(:light_video), do: "text-pink-300"
  defp get_style_by_type(:emoji), do: "not-italic"
  defp get_style_by_type(_), do: ""
end
