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

            {room_server, _room} = RoomSupervisor.get_room_server(RoomSupervisor, room.id)

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

    # %{room: %{slug: slug}} = socket.assigns
    # presence = list_filtered_present(slug, socket.id)

    # case presence do
    #   [] ->
    #     %{videos: videos} = socket.assigns

    #     case Enum.at(videos, 0) do
    #       nil ->
    #         {:noreply, socket}

    #       video ->
    #         {:noreply,
    #          socket
    #          |> assign(:page_title, page_title(video))
    #          |> push_event("receive_player_state", %{
    #            videoId: video.video_id,
    #            shouldPlay: true,
    #            time: 0
    #          })}
    #     end

    #   _ps ->
    #     Phoenix.PubSub.subscribe(DjRumble.PubSub, "room:" <> slug <> ":request_initial_state")
    #     # Tells every node the requester node needs an initial state
    #     :ok =
    #       Phoenix.PubSub.broadcast_from(
    #         DjRumble.PubSub,
    #         self(),
    #         "room:" <> socket.assigns.room.slug,
    #         {:request_initial_state, %{}}
    #       )

    #     {:noreply, socket}
    # end
  end

  @impl true
  def handle_event("next_video", _params, socket) do
    %{videos: videos, index_playing: index_playing} = socket.assigns
    next_index_playing = index_playing + 1
    next_video = Enum.at(videos, next_index_playing)

    case next_video != nil do
      false ->
        {:noreply, socket}

      true ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(next_video))
         |> assign(:index_playing, next_index_playing)
         |> push_event("receive_player_state", %{
           videoId: next_video.video_id,
           shouldPlay: true,
           time: 0
         })}
    end
  end

  @impl true
  def handle_event("receive_current_video_time", current_time, socket) do
    %{room: room} = socket.assigns

    case socket.id == room.video_tracker do
      true ->
        Phoenix.PubSub.broadcast(
          DjRumble.PubSub,
          "room:" <> room.slug,
          {:receive_current_video_time, %{time: current_time}}
        )

        {:noreply, socket}

      false ->
        {:noreply, socket}
    end
  end

  def handle_info({:request_initial_state, _params}, socket) do
    %{videos: videos, index_playing: index_playing, current_video_time: current_video_time} =
      socket.assigns

    :ok =
      Phoenix.PubSub.broadcast_from(
        DjRumble.PubSub,
        self(),
        "room:" <> socket.assigns.room.slug <> ":request_initial_state",
        {:receive_initial_state,
         %{
           videos: videos,
           index_playing: index_playing,
           current_video_time: current_video_time
         }}
      )

    {:noreply, socket}
  end

  def handle_info({:receive_initial_state, params}, socket) do
    %{room: %{slug: slug}} = socket.assigns
    Phoenix.PubSub.unsubscribe(DjRumble.PubSub, "room:" <> slug <> ":request_initial_state")

    %{videos: videos, index_playing: index_playing, current_video_time: current_video_time} =
      params

    socket =
      socket
      |> assign(:videos, videos)
      |> assign(:index_playing, index_playing)
      |> assign(:current_video_time, current_video_time)

    case videos do
      [] ->
        {:noreply, socket}

      _xs ->
        %{video_id: video_id} = Enum.at(videos, index_playing)

        {:noreply,
         socket
         |> push_event("receive_player_state", %{
           shouldPlay: true,
           time: current_video_time,
           videoId: video_id
         })}
    end
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

  def handle_info({:receive_current_video_time, %{time: time}}, socket) do
    {:noreply,
     socket
     |> assign(:current_video_time, time)}
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

  def handle_info({:round_started, params}, socket), do: handle_round_start(params, socket)

  @doc """
  Receives a welcoming message when joining a room.

  * **From:** `Matchmaking`
  * **Topic:** Direct message
  * **Args:** `String`
  """
  def handle_welcome_message(_message, socket) do
    {:noreply, socket}
  end

  @doc """
  Receives video details when a round is prepared.

  * **From:** `Matchmaking`
  * **Topic:** `"room:<room_id>:ready"`
  * **Args:** `%{videoId: video_id, time: 0}`
  """
  def handle_playback_details(video_details, socket) do
    Logger.info(fn -> "Received video details" end)

    {:noreply,
     socket
     |> push_event("receive_player_state", video_details)}
  end

  @doc """
  Receives details when a round is started

  * **From:** `Matchmaking`
  * **Topic:** `"room:<room_id>:ready"`
  * **Args:** `%Round.InProgress{}`
  """
  def handle_round_start(%Round.InProgress{} = round, socket) do
    Logger.info(fn -> "Round Started: #{inspect(round)}" end)

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
