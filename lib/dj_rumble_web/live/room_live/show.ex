defmodule DjRumbleWeb.RoomLive.Show do
  @moduledoc """
  Responsible for controlling the Show room live view
  """

  use DjRumbleWeb, :live_view

  require Logger

  alias DjRumble.Repo
  alias DjRumble.Rooms
  alias DjRumble.Rooms.{RoomServer, RoomSupervisor}
  alias DjRumble.Rounds.Round
  alias DjRumbleWeb.Presence
  alias Faker

  def get_list_from_slug(slug) do
    Presence.list("room:#{slug}")
    |> Enum.map(fn {uuid, %{metas: metas}} -> %{uuid: uuid, metas: metas} end)
  end

  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    case connected?(socket) do
      true ->
        case Rooms.get_room_by_slug(slug) do
          nil ->
            {:ok,
             socket
             |> put_flash(:error, "That room does not exist.")
             |> push_redirect(to: Routes.room_index_path(socket, :index))}

          room ->
            %{assigns: %{user: user}} = socket = assign_defaults(socket, params, session)

            {room_server, _room} = RoomSupervisor.get_room_server(RoomSupervisor, room.slug)

            room = Repo.preload(room, [:videos])
            index_playing = 0

            topic = "room:#{slug}"
            connected_users = get_list_from_slug(slug)

            # Subscribe to the topic
            DjRumbleWeb.Endpoint.subscribe(topic)

            # Track changes to the topic
            Presence.track(
              self(),
              topic,
              socket.id,
              %{username: user.username}
            )

            {:ok,
             socket
             |> assign(:videos, room.videos)
             |> assign_tracker(room)
             |> assign(:index_playing, index_playing)
             |> assign(:connected_users, connected_users)
             |> assign(:current_video_time, 0)
             |> assign(:round_info, "")
             |> assign(:room_server, room_server)}
        end

      false ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_is_ready", _params, socket) do
    %{room: room} = socket.assigns

    Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:#{room.slug}:ready")

    :ok = RoomServer.join(socket.assigns.room_server)

    {:noreply, socket}
  end

  @impl true
  def handle_event("receive_video_time", time, socket) do
    Logger.info(fn -> "Received time: '#{time}' from yt client" end)

    :ok =
      Phoenix.PubSub.broadcast(
        DjRumble.PubSub,
        "matchmaking:#{socket.assigns.room.slug}:waiting_for_details",
        {:receive_video_time, time}
      )

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: payload},
        %{assigns: %{room: %{slug: slug}}} = socket
      ) do
    connected_users = get_list_from_slug(slug)

    room = handle_video_tracker_activity(slug, connected_users, payload)

    socket =
      socket
      |> assign(:connected_users, connected_users)
      |> assign(:room, room)

    case is_my_presence(socket.id, payload) do
      false ->
        {:noreply,
         socket
         |> push_event("presence-changed", %{})}

      true ->
        {:noreply, socket}
    end
  end

  def handle_info({:add_to_queue, params}, %{assigns: assigns} = socket) do
    %{new_video: new_video} = params

    %{videos: videos} = assigns

    videos = videos ++ [new_video]

    {:noreply,
     socket
     |> assign(:videos, videos)}
  end

  def handle_info({:welcome, params}, socket), do: handle_welcome_message(params, socket)

  def handle_info({:receive_playback_details, params}, socket),
    do: handle_playback_details(params, socket)

  def handle_info({:request_playback_details, params}, socket),
    do: handle_playback_details_request(params, socket)

  def handle_info({:round_started, params}, socket), do: handle_round_started(params, socket)

  def handle_info(:no_more_rounds, socket), do: handle_no_more_rounds(socket)

  def handle_info({:receive_countdown, params}, socket),
    do: handle_receive_countdown(params, socket)

  def handle_info({:round_scheduled, params}, socket), do: handle_round_scheduled(params, socket)

  def handle_info({:round_finished, params}, socket), do: handle_round_finished(params, socket)

  @doc """
  Receives a welcoming message when joining a room.

  * **From:** `Matchmaking`
  * **Topic:** Direct message
  * **Args:** `String.t()`
  """
  def handle_welcome_message(_message, socket) do
    {:noreply, socket}
  end

  @doc """
  Receives a message telling a round has been scheduled.

  * **From:** `Matchmaking`
  * **Topic:** `"room:<room_slug>"`
  * **Args:** `%Round.Scheduled{}`
  """
  def handle_round_scheduled(round, socket) do
    Logger.info(fn -> "Receives a scheduled round: #{inspect(round)}" end)

    {:noreply, socket}
  end

  @doc """
  Receives video details when a round is prepared.

  * **From:** `Matchmaking`
  * **Topic:** `"room:<room_slug>:ready"`
  * **Args:** `%{videoId: String.t(), time: non_neg_integer()}`
  """
  def handle_playback_details(video_details, socket) do
    Logger.info(fn -> "Received video details: #{inspect(video_details)}" end)

    {:noreply,
     socket
     |> push_event("receive_player_state", video_details)}
  end

  @doc """
  Receives video details when a round is prepared.

  * **From:** `Matchmaking`
  * **Topic:** `"room:<room_slug>:ready"`
  * **Args:** `%{videoId: String.t(), time: non_neg_integer()}`
  """
  def handle_playback_details_request(video_details, socket) do
    Logger.info(fn ->
      "[Pid #{inspect(self())}] receives playback details request for video time."
    end)

    {:noreply,
     socket
     |> push_event("playback_details_request", video_details)}
  end

  @doc """
  Receives a message telling a round will start in `seconds` seconds.

  * **From:** `Matchmaking`
  * **Topic:** `String.t()`. Example: `"room:<room_slug>"`
  * **Args:** `non_neg_integer()`
  """
  def handle_receive_countdown(seconds, socket) do
    one_second = :timer.seconds(1)

    socket =
      case seconds do
        0 ->
          assign(socket, :round_info, "")

        _ ->
          Process.send_after(self(), {:receive_countdown, seconds - one_second}, one_second)
          assign(socket, :round_info, "Round starts in #{div(seconds, one_second)}")
      end

    Logger.info(fn -> "Countdown: #{div(seconds, one_second)} seconds until room starts." end)

    {:noreply, socket}
  end

  @doc """
  Receives details when a round is started

  * **From:** `Matchmaking`
  * **Topic:** `String.t()`. Example: `"room:<room_slug>:ready"`
  * **Args:** `%Round.InProgress{}`
  """
  def handle_round_started(
        %{round: %Round.InProgress{} = round, video_details: video_details},
        socket
      ) do
    Logger.info(fn -> "Round Started: #{inspect(round)}" end)

    {:noreply,
     socket
     |> push_event("receive_player_state", video_details)}
  end

  @doc """
  Receives details when a round is finished

  * **From:** `Matchmaking`
  * **Topic:** `String.t()`. Example: `"room:<room_slug>"`
  * **Args:** `%Round.Finished{}`
  """
  def handle_round_finished(%Round.Finished{} = round, socket) do
    Logger.info(fn -> "Round Finished: #{inspect(round)}" end)

    {:noreply,
     socket
     |> assign(:round_info, "Round finished. Results...")}
  end

  @doc """
  Receives a message telling there are no more rounds

  * **From:** `Matchmaking`
  * **Topic:** `String.t()`. Example: `"room:<room_slug>:ready"`
  """
  def handle_no_more_rounds(socket) do
    Logger.info(fn -> "No more rounds" end)

    {:noreply, socket}
  end

  defp page_title(:show), do: "Show Room"

  defp page_title(:edit), do: "Edit Room"

  defp page_title(video) do
    case video do
      nil -> ""
      _ -> video.title
    end
  end

  defp list_filtered_present(slug, uuid) do
    Presence.list("room:" <> slug)
    |> Enum.filter(fn {k, _} -> k !== uuid end)
    |> Enum.map(fn {k, _} -> k end)
  end

  defp assign_tracker(socket, room) do
    current_user = socket.id

    case list_filtered_present(room.slug, current_user) do
      [] ->
        {:ok, updated_room} = Rooms.update_room(room, %{video_tracker: current_user})

        socket
        |> assign(:room, updated_room)

      _xs ->
        socket
        |> assign(:room, room)
    end
  end

  defp handle_video_tracker_activity(slug, presence, %{leaves: leaves}) do
    room = Rooms.get_room_by_slug(slug)
    video_tracker = room.video_tracker

    case video_tracker in Map.keys(leaves) do
      false ->
        room

      true ->
        case presence do
          [] ->
            {:ok, updated_room} = Rooms.update_room(room, %{video_tracker: ""})
            updated_room

          [p | _ps] ->
            {:ok, updated_room} = Rooms.update_room(room, %{video_tracker: p.uuid})
            updated_room
        end
    end
  end

  defp is_my_presence(id, presence_payload) do
    Enum.any?(Map.to_list(presence_payload.joins), fn {x, _} -> x == id end) ||
      Enum.any?(Map.to_list(presence_payload.leaves), fn {x, _} -> x == id end)
  end
end
