defmodule DjRumbleWeb.Live.Components.PlayerControls do
  @moduledoc """
  Responsible for displaying the player controls
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.RoomServer

  def update(%{room_server: room_server}, socket) do
    {:ok,
     socket
     |> assign(:room_server, room_server)}
  end

  def handle_event("score", %{"score" => type}, socket) do
    %{room_server: room_server} = socket.assigns

    :ok = RoomServer.score(room_server, self(), String.to_atom(type))

    {:noreply, socket}
  end

  defp render_score_button(type, assigns) do
    icon =
      case type do
        :positive -> "like"
        :negative -> "dislike"
      end

    id = "djrumble-score-#{Atom.to_string(type)}"

    ~L"""
      <a
        id="<%= id %>"
        class=""
        phx-click="score"
        phx-value-score=<%= type %>
        phx-target="<%= assigns %>"
      >
        <%= PhoenixInlineSvg.Helpers.svg_image(
            DjRumbleWeb.Endpoint,
            "buttons/#{icon}",
            class: "h-12 w-12 score-button cursor-pointer transform hover:scale-110"
          )
        %>
      </a>
    """
  end
end
