defmodule DjRumbleWeb.RoomLive.Index do
  @moduledoc """
  Responsible for controlling the Room list live view
  """
  use DjRumbleWeb, :live_view

  alias DjRumble.Repo
  alias DjRumble.Rooms
  alias DjRumble.Rooms.Room
  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor}

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(socket, params, session)

    rooms =
      list_rooms()
      |> Enum.map(fn room -> Repo.preload(room, [:videos, users_rooms_videos: [:video]]) end)

    matchmaking_servers =
      MatchmakingSupervisor.list_matchmaking_servers(MatchmakingSupervisor)
      |> Enum.map(&Matchmaking.get_state(&1))

    # IO.inspect(matchmaking_servers, label: "matchmaking_servers")

    {:ok,
     socket
     |> assign(:matchmaking_servers, matchmaking_servers)
     |> assign(:rooms, rooms)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_event("redirect_room", %{"slug" => slug}, socket) do
    {:noreply,
     socket
     |> redirect(to: Routes.room_show_path(socket, :show, slug))}
  end

  defp list_rooms do
    Rooms.list_rooms()
  end
end
