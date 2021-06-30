defmodule DjRumbleWeb.RoomLive.Index do
  @moduledoc """
  Responsible for controlling the Room list live view
  """
  use DjRumbleWeb, :live_view

  alias DjRumble.Rooms.Room
  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor}

  alias DjRumbleWeb.Channels

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(socket, params, session)

    rooms = initialise_rooms()

    :ok = subscribe_to_room_topics(rooms)

    {:ok,
     socket
     |> assign_rooms(rooms)}
  end

  @impl true
  def handle_info({:receive_current_player, params}, socket),
    do: handle_video_is_playing(params, socket)

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp handle_video_is_playing(
         %{current_round: current_round, room: room, status: status, videos: videos},
         socket
       ) do
    send_update(
      DjRumbleWeb.Live.Components.RoomCard,
      id: "dj-rumble-room-card-#{room.slug}",
      current_round: current_round,
      room: room,
      status: status,
      videos: videos
    )

    {:noreply, socket}
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

  defp assign_rooms(socket, rooms) do
    assign(socket, :rooms, rooms)
  end

  defp initialise_rooms do
    MatchmakingSupervisor.list_matchmaking_servers(MatchmakingSupervisor)
    |> Enum.map(&Matchmaking.get_state(&1))
    |> Enum.reduce([], fn matchmaking_server, acc ->
      %{current_round: current_round, room: room, status: status} = matchmaking_server

      videos = Enum.map(room.users_rooms_videos, & &1.video)

      {_ref, {_pid, video, _time, user}} = current_round

      acc ++ [{%{video: video, added_by: user}, room, status, videos}]
    end)
  end

  defp subscribe_to_room_topics(rooms) do
    :ok =
      Enum.each(rooms, fn {_, room, _, _} ->
        :ok = Channels.subscribe(:lobby, room.slug)
      end)
  end
end
