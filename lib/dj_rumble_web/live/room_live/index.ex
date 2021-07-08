defmodule DjRumbleWeb.RoomLive.Index do
  @moduledoc """
  Responsible for controlling the Room list live view
  """
  use DjRumbleWeb, :live_view

  alias DjRumble.Rooms.Room
  alias DjRumble.Rooms.{Matchmaking, MatchmakingSupervisor}
  alias DjRumbleWeb.Channels
  alias DjRumbleWeb.Presence

  @users_count_tick_rate :timer.seconds(2)

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(socket, params, session)

    rooms = initialise_rooms()

    :ok = subscribe_to_room_topics(rooms)

    schedule_next_users_count_tick()

    {:ok,
     socket
     |> assign_rooms(rooms)
     |> assign_users_count(Map.new())}
  end

  @impl true
  def handle_event("close_new_room_modal", _, socket) do
    {:noreply, push_patch(socket, to: Routes.room_index_path(socket, :index))}
  end

  @impl true
  def handle_event("new_live_patch", _params, socket) do
    {:noreply, push_patch(socket, to: Routes.room_index_path(socket, :new))}
  end

  @impl true
  def handle_event("redirect_room", %{"slug" => slug}, socket) do
    {:noreply,
     socket
     |> redirect(to: Routes.room_show_path(socket, :show, slug))}
  end

  @impl true
  def handle_info({:receive_current_player, params}, socket),
    do: handle_video_is_playing(params, socket)

  @impl true
  def handle_info(:fetch_users_count, socket), do: handle_fetch_users_count(socket)

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

  defp handle_fetch_users_count(socket) do
    schedule_next_users_count_tick()

    {:noreply,
     socket
     |> assign_users_count(socket.assigns.users_count)}
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

  defp assign_users_count(socket, users_count) do
    %{rooms: rooms} = socket.assigns

    users_count =
      Enum.reduce(rooms, users_count, fn {_video_user, room, _status, _videos}, users_count ->
        count = get_users_count(room.slug)
        Map.put(users_count, room.slug, count)
      end)

    assign(socket, :users_count, users_count)
  end

  defp get_users_count(slug) do
    Presence.list(DjRumbleWeb.Channels.get_topic(:room, slug))
    |> Enum.map(fn {uuid, %{metas: metas}} -> %{uuid: uuid, metas: metas} end)
    |> length()
  end

  defp schedule_next_users_count_tick do
    Process.send_after(self(), :fetch_users_count, @users_count_tick_rate)
  end
end
