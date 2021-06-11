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

    {:ok,
     socket
     |> assign(:current_round, current_round)
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

    id = "djrumble-score-#{Atom.to_string(type)}"

    ~L"""
      <a
        id="<%= id %>"
        class=""
        phx-click="score"
        phx-value-score=<%= type %>
        phx-target="<%= assigns %>"
      >
        <%= icon %>
      </a>
    """
  end

  defp render_dj(current_round, assigns) do
    case Map.get(current_round, :user) do
      nil ->
        ~L"""
        """

      user ->
        ~L"""
          by, <span class="text-indigo-900"><%= user.username%></span>
        """
    end
  end

  defp parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
