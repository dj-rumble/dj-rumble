defmodule DjRumbleWeb.Live.Components.PlayerControls.ScorePanel do
  @moduledoc """
  Responsible for displaying a live score and scoring buttons
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.RoomServer

  def update(assigns, socket) do
    %{
      id: id,
      current_round: current_round,
      live_score: live_score,
      room_server: room_server,
      scoring_enabled: scoring_enabled,
      user: user,
      visitor: visitor
    } = assigns

    {:ok,
     socket
     |> assign(:id, id)
     |> assign(:current_round, current_round)
     |> assign(:live_score, live_score)
     |> assign(:room_server, room_server)
     |> assign(:scoring_enabled, scoring_enabled)
     |> assign(:user, user)
     |> assign(:visitor, visitor)}
  end

  def handle_event("score", _params, %{assigns: %{visitor: true}} = socket),
    do: {:noreply, socket}

  def handle_event("score", %{"score" => type}, %{assigns: %{visitor: false}} = socket) do
    %{room_server: room_server, user: user} = socket.assigns
    type = String.to_atom(type)

    :ok = RoomServer.score(room_server, user, type)

    {:noreply, socket}
  end

  defp render_score_button(type, is_scoring_enabled, visitor, current_round, assigns) do
    {icon, tooltip_text} =
      case type do
        :positive ->
          case Map.get(current_round, :added_by) do
            nil -> {"like", ""}
            user -> {"like", "Watch more videos from #{user.username} by supporting this Dj"}
          end

        :negative ->
          {"dislike", "Definitely not today"}
      end

    id = "djrumble-score-#{Atom.to_string(type)}"

    shared_classes =
      "cursor-pointer shadow-2xl transition duration-500 ease-in-out transform hover:scale-110 hover:shadow-sm"

    case is_scoring_enabled do
      true ->
        classes = "#{shared_classes} enabled"

        ~L"""
          <div id="<%= id %>">
            <div class="group relative w-full flex justify-center">
              <a
                phx-click="score"
                phx-value-score=<%= type %>
                phx-target="<%= assigns %>"
              >
                <%= render_svg_button(icon, classes) %>
              </a>
              <%= render_tooltip(text: tooltip_text, extra_classes: "text-xl") %>
            </div>
          </div>
        """

      false ->
        classes = "#{shared_classes} disabled"

        {click, event} =
          case visitor do
            true -> {"open", "#djrumble-register-modal-menu"}
            false -> {"", ""}
          end

        ~L"""
          <div id="<%= id %>">
            <div class="group relative w-full flex justify-center">
              <a
                phx-click="<%= click %>"
                phx-target="<%= event %>"
              >
                <%= render_svg_button(icon, classes) %>
              </a>
              <%= render_tooltip(text: "Voting is disabled", extra_classes: "text-xl") %>
            </div>
          </div>
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
