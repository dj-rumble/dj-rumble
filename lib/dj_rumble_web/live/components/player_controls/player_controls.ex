defmodule DjRumbleWeb.Live.Components.PlayerControls do
  @moduledoc """
  Responsible for displaying the player controls
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.RoomServer

  def update(assigns, socket) do
    %{
      live_score: live_score,
      room_server: room_server,
      scoring_enabled: scoring_enabled,
      visitor: visitor
    } = assigns

    {:ok,
     socket
     |> assign(:live_score, live_score)
     |> assign(:scoring_enabled, scoring_enabled)
     |> assign(:visitor, visitor)
     |> assign(:room_server, room_server)}
  end

  def handle_event("score", %{"score" => type}, socket) do
    %{room_server: room_server} = socket.assigns

    :ok = RoomServer.score(room_server, self(), String.to_atom(type))

    {:noreply, socket}
  end

  defp render_score_button(type, is_scoring_enabled, visitor, assigns) do
    icon =
      case type do
        :positive -> "like"
        :negative -> "dislike"
      end

    id = "djrumble-score-#{Atom.to_string(type)}"

    shared_classes =
      "cursor-pointer shadow-2xl transition duration-500 ease-in-out transform hover:scale-110 hover:shadow-sm"

    case is_scoring_enabled do
      true ->
        classes = "#{shared_classes} enabled"

        ~L"""
          <a
            id="<%= id %>"
            phx-click="score"
            phx-value-score=<%= type %>
            phx-target="<%= assigns %>"
          >
            <%= render_svg_button(icon, classes) %>
          </a>
        """

      false ->
        classes = "#{shared_classes} disabled"

        {click, event} =
          case visitor do
            true -> {"open", "#djrumble-register-modal-menu"}
            false -> {"", ""}
          end

        ~L"""
          <a
            id="<%= id %>"
            phx-click="<%= click %>"
            phx-target="<%= event %>"
          >
            <%= render_svg_button(icon, classes) %>
          </a>
        """
    end
  end

  defp render_svg_button(icon, classes) do
    PhoenixInlineSvg.Helpers.svg_image(
      DjRumbleWeb.Endpoint,
      "buttons/#{icon}",
      class: "h-16 w-16 score-button #{classes}"
    )
  end
end
