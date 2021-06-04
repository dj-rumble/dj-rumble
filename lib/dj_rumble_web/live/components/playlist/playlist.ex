defmodule DjRumbleWeb.Live.Components.Playlist do
  @moduledoc """
  Responsible for showing the queue of videos to be played
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.RoomServer

  def update(assigns, socket) do
    %{
      current_round: current_round,
      next_rounds: next_rounds,
      room_server: room_server
    } = assigns

    videos =
      next_rounds
      |> Enum.map(fn %{video: video} -> video end)
      |> Enum.with_index()

    %{video: current_video} = current_round

    {:ok,
     socket
     |> assign(:current_video, current_video)
     |> assign(:room_server, room_server)
     |> assign(:videos, videos)}
  end

  def handle_event("score", %{"score" => type}, socket) do
    %{room_server: room_server} = socket.assigns

    :ok = RoomServer.score(room_server, self(), String.to_atom(type))

    {:noreply, socket}
  end

  defp render_score_button(type, assigns) do
    icon =
      case type do
        :positive -> "👍"
        :negative -> "👎"
      end

    ~L"""
      <a
        id="<%= Atom.to_string(:type) %>"
        class=""
        phx-click="score"
        phx-value-score=<%= type %>
        phx-target="<%= assigns %>"
      >
        <%= icon %>
      </a>
    """
  end

  defp parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
