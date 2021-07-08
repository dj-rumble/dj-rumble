defmodule DjRumbleWeb.Live.Components.PlayerControls.ScorePanel do
  @moduledoc """
  Responsible for displaying a live score and scoring buttons
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.RoomServer

  @register_modal_menu_id "#djrumble-register-modal-menu"

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

  def handle_event("score", params, %{assigns: %{visitor: false}} = socket) do
    case params do
      %{"score" => "positive"} ->
        handle_score(:positive, socket)

      %{"score" => "negative"} ->
        handle_score(:negative, socket)

      _ ->
        {:noreply, socket}
    end
  end

  @doc """
  Given a score `type` and a `socket`, tells the room server to score a vote
  for a `user`.
  """
  def handle_score(type, socket) do
    %{room_server: room_server, user: user} = socket.assigns

    :ok = RoomServer.score(room_server, user, type)

    {:noreply, socket}
  end

  defp render_score_button(type, is_scoring_enabled, is_visitor, current_round, assigns) do
    id = "djrumble-score-#{Atom.to_string(type)}"

    {event, event_value, event_target} =
      get_event_data(is_visitor, is_scoring_enabled, type, assigns)

    icon = get_icon_by_type(type)
    icon_classes = get_icon_classes(is_scoring_enabled)
    tooltip_text = get_tooltip_text(type, current_round)

    render_button(id, event, event_value, event_target, icon, icon_classes, tooltip_text, assigns)
  end

  defp render_button(
         id,
         event,
         event_value,
         event_target,
         icon,
         icon_classes,
         tooltip_text,
         assigns
       ) do
    default_classes =
      "cursor-pointer shadow-2xl transition duration-500 ease-in-out transform hover:scale-110 hover:shadow-sm"

    icon_classes = "#{default_classes} #{icon_classes}"

    ~L"""
      <div id="<%= id %>">
        <div class="group relative w-full flex justify-center">
          <a
            id="<%= id %>-button"
            phx-click="<%= event %>"
            phx-value-score="<%= event_value %>"
            phx-target="<%= event_target %>"
          >
            <%= render_svg_button(icon, icon_classes) %>
          </a>
          <%= render_tooltip(text: tooltip_text, extra_classes: "text-xl") %>
        </div>
      </div>
    """
  end

  defp render_svg_button(icon, classes) do
    PhoenixInlineSvg.Helpers.svg_image(
      DjRumbleWeb.Endpoint,
      "buttons/#{icon}",
      class: "h-16 w-16 score-button #{classes}"
    )
  end

  defp get_event_data(false = _visitor, true = _is_scoring_enabled, vote_type, assigns) do
    {"score", vote_type, assigns}
  end

  defp get_event_data(false = _visitor, false = _is_scoring_enabled, _vote_type, _assigns) do
    {"", "", nil}
  end

  defp get_event_data(_visitor, false = _is_scoring_enabled, _vote_type, _assigns) do
    {"open", nil, @register_modal_menu_id}
  end

  defp get_icon_by_type(:positive), do: "like"
  defp get_icon_by_type(:negative), do: "dislike"

  defp get_icon_classes(true), do: "enabled"
  defp get_icon_classes(false), do: "disabled"

  defp get_tooltip_text(:positive, current_round) do
    case Map.get(current_round, :added_by) do
      nil -> "Upvote"
      user -> "Watch more videos from #{user.username} by supporting this Dj"
    end
  end

  defp get_tooltip_text(:negative, _current_round) do
    # Add a line here to mixup downvotes text. You may use `current_round` to
    # add video and user information into the tooltip text.
    texts = [
      "Downvote to move this video from the queue"
    ]

    Enum.at(texts, Enum.random(0..(length(texts) - 1)))
  end
end
