defmodule DjRumbleWeb.RoomLive.Show do
  @moduledoc """
  Responsible for controlling the Show room live view
  """

  use DjRumbleWeb, :live_view

  require Logger

  alias DjRumble.Collections
  alias DjRumble.Repo
  alias DjRumble.Rooms
  alias DjRumble.Rooms.{MatchmakingSupervisor, RoomServer, RoomSupervisor}
  alias DjRumble.Rounds.Round
  alias DjRumbleWeb.Channels
  alias DjRumbleWeb.Presence
  alias Faker

  @tick_rate :timer.seconds(2)

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

            {matchmaking_server, _state} =
              MatchmakingSupervisor.get_matchmaking_server(MatchmakingSupervisor, room.slug)

            next_rounds = RoomServer.list_next_rounds(matchmaking_server)
            current_round = RoomServer.get_current_round(matchmaking_server)

            send(self(), :tick)

            room = Repo.preload(room, [:videos])

            topic = Channels.get_topic(:room, slug)
            connected_users = get_list_from_slug(slug)

            # Subscribe to the topic
            :ok = DjRumbleWeb.Endpoint.subscribe(topic)

            # Track changes to the topic
            {:ok, _} =
              Presence.track(
                self(),
                topic,
                socket.id,
                %{username: user.username, user_id: user.id}
              )

            :ok = Channels.subscribe(:score, slug)

            {:ok,
             socket
             |> assign(:connected_users, connected_users)
             |> assign(:joined, false)
             |> assign(:live_score, 0)
             |> assign(:matchmaking_server, matchmaking_server)
             |> assign(:room, room)
             |> assign(:room_server, room_server)
             |> assign(:round_info, "")
             |> assign(:current_round, current_round)
             |> assign(:next_rounds, next_rounds)
             |> assign_scoring(:disable)
             |> assign(:searchbox_state, "CLOSED")
             |> assign(:register_modal_state, "CLOSED")
             |> assign(:show_search_modal, false)
             |> assign_chat(room)}
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

    case socket.assigns.joined do
      false ->
        :ok = Channels.subscribe(:player_is_ready, room.slug)

        :ok = RoomServer.join(socket.assigns.room_server)

        {:noreply,
         socket
         |> assign(:joined, true)}

      true ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("receive_video_time", %{"duration" => time}, socket) do
    Logger.info(fn -> "Received time: '#{time}' from yt client" end)

    :ok =
      Channels.broadcast(
        :matchmaking_details_request,
        socket.assigns.room.slug,
        {:receive_video_time, time}
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("throw_confetti_interaction", _, socket) do
    :ok =
      Channels.broadcast(
        :room,
        socket.assigns.room.slug,
        {:throw_confetti_interaction, %{user: socket.assigns.user.username}}
      )

    {:noreply, socket}
  end

  @impl true
  def handle_event("open_search_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_search_modal, true)}
  end

  @impl true
  def handle_event("close_search_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_search_modal, false)}
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: _payload},
        %{assigns: %{room: %{slug: slug}}} = socket
      ) do
    connected_users = get_list_from_slug(slug)

    {:noreply,
     socket
     |> assign(:connected_users, connected_users)}
  end

  def handle_info(:tick, socket), do: handle_tick(%{}, socket)

  def handle_info({:welcome, params}, socket), do: handle_welcome_message(params, socket)

  def handle_info({:create_round, params}, socket), do: handle_create_round(params, socket)

  def handle_info({:receive_playback_details, params}, socket),
    do: handle_playback_details(params, socket)

  def handle_info({:receive_new_message, params}, socket),
    do: handle_receive_new_message(params, socket)

  def handle_info({:request_playback_details, params}, socket),
    do: handle_playback_details_request(params, socket)

  def handle_info({:round_started, params}, socket), do: handle_round_started(params, socket)

  def handle_info(:no_more_rounds, socket), do: handle_no_more_rounds(socket)

  def handle_info({:receive_countdown, params}, socket),
    do: handle_receive_countdown(params, socket)

  def handle_info({:round_scheduled, params}, socket), do: handle_round_scheduled(params, socket)

  def handle_info({:round_finished, params}, socket), do: handle_round_finished(params, socket)

  def handle_info({:receive_score, params}, socket), do: handle_receive_score(params, socket)

  def handle_info({:outcome_changed, params}, socket), do: handle_outcome_changed(params, socket)

  def handle_info({:check_scoring_permission, params}, socket),
    do: handle_check_scoring_permission(params, socket)

  def handle_info({:throw_confetti_interaction, params}, socket),
    do: handle_throw_confetti_interaction(params, socket)

  @doc """
  Receives a local message to continuously update the Liveview

  * **From:** `self()`
  * **Topic:** Direct message
  * **Args:** `%{}`
  """
  def handle_tick(_params, socket) do
    %{assigns: %{matchmaking_server: matchmaking_server}} = socket
    schedule_next_tick()

    socket =
      socket
      |> assign(:next_rounds, RoomServer.list_next_rounds(matchmaking_server))

    {:noreply, socket}
  end

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
  Receives a new video and tells the server to create a Round with it.

  * **From:** `SearchBox`
  * **Topic:** Direct message
  * **Args:** `%Video{}`
  """
  def handle_create_round(video, %{assigns: assigns} = socket) do
    case assigns.visitor do
      true ->
        {:noreply, socket}

      false ->
        %{
          matchmaking_server: matchmaking_server,
          room: %{id: room_id},
          user: %{id: user_id} = user
        } = assigns

        {:ok, video} = Rooms.create_video(Map.from_struct(video))

        {:ok, _room_video} = Rooms.create_room_video(%{room_id: room_id, video_id: video.id})

        {:ok, _user_room_video} =
          Collections.create_user_room_video(%{
            room_id: room_id,
            user_id: user_id,
            video_id: video.id
          })

        :ok = RoomServer.create_round(matchmaking_server, video, user)

        {:noreply, socket}
    end
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
  %{round: round, video: video, video_details: video_details, added_by: user
  * **Args:** `%{video_details: %{videoId: String.t(), time: non_neg_integer(), title: String.t()}, round: %Round.InProgress{}, video: %Video{}, added_by: %User{}}`
  """
  def handle_playback_details(params, socket) do
    %{video: video, video_details: video_details, added_by: user, round: round} = params

    Logger.info(fn ->
      "Received video details: #{inspect(video_details)}, added by: #{inspect(user)}"
    end)

    {:noreply,
     socket
     |> assign_page_title(video.title)
     |> assign(:current_round, params)
     |> assign_live_score(round)
     |> push_event("receive_player_state", video_details)}
  end

  @doc """
  Receives a new chat message

  * **From:** `ChatServer`
  * **Topic:** `"room:<slug>:chat"`
  * **Params:** `%Message{}`
  """
  @spec handle_receive_new_message(DjRumble.Chats.Message, Phoenix.LiveView.Socket.t()) ::
          {:noreply, map}
  def handle_receive_new_message(message, socket) do
    %{assigns: %{chat_messages: chat_messages}} = socket

    chat_messages = chat_messages ++ [message]

    {:noreply,
     socket
     |> assign(:chat_messages, chat_messages)
     |> push_event("receive_new_message", %{})}
  end

  @doc """
  Receives video details when a round is prepared.

  * **From:** `Matchmaking`
  * **Topic:** `"room:<room_slug>:ready"`
  * **Args:** `%{videoId: String.t(), time: non_neg_integer()}`
  """
  def handle_playback_details_request(video_details, socket) do
    # coveralls-ignore-start
    Logger.info(fn ->
      "[Pid #{inspect(self())}] receives playback details request for video time."
    end)

    # coveralls-ignore-stop

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
          socket
          |> assign(:round_info, "")
          |> assign_page_title("Countdown: 0")

        _ ->
          Process.send_after(self(), {:receive_countdown, seconds - one_second}, one_second)
          remaining_seconds = div(seconds, one_second)

          socket
          |> assign(:round_info, "Video starts in #{remaining_seconds}")
          |> assign_page_title("Countdown: #{remaining_seconds}")
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
        %{
          round: %Round.InProgress{} = round,
          video_details: video_details,
          added_by: user,
          video: video
        } = current_round,
        socket
      ) do
    Logger.info(fn -> "Round Started: #{inspect(round)}, added by #{inspect(user)}" end)

    {:noreply,
     socket
     |> assign_page_title(video.title)
     |> assign(:current_round, current_round)
     |> assign_scoring(:check_user)
     |> assign_live_score(round)
     |> push_event("receive_player_state", video_details)}
  end

  @doc """
  Receives details when a round is finished

  * **From:** `Matchmaking`
  * **Topic:** `String.t()`. Example: `"room:<room_slug>"`
  * **Args:** `%Round.Finished{}`
  """
  def handle_round_finished(
        %{round: %Round.Finished{outcome: :continue} = round, video_details: video_details} =
          current_round,
        socket
      ) do
    Logger.info(fn -> "Round Finished: #{inspect(round)}" end)

    short_title = String.slice(video_details.title, 0, 15)

    {:noreply,
     socket
     |> assign_scoring(:disable)
     |> assign(:current_round, current_round)
     |> assign(:round_info, "#{short_title}... scored #{get_score(round.score)} points")
     |> push_event("drop_confetti", %{})}
  end

  def handle_round_finished(
        %{round: %Round.Finished{} = round, video_details: video_details} = current_round,
        socket
      ) do
    Logger.info(fn -> "Round Finished: #{inspect(round)}" end)

    short_title = String.slice(video_details.title, 0, 15)

    {:noreply,
     socket
     |> assign_scoring(:disable)
     |> assign(:current_round, current_round)
     |> assign(:round_info, "#{short_title}... scored #{get_score(round.score)} points")}
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

  @doc """
  Receives a %Round.InProgress{} score

  * **From:** `RoomServer` (broadcast)
  * **Topic:** `"room:<slug>"`
  * **Args:** `{:positive | :negative, %Round.InProgress{}}`
  """
  def handle_receive_score(%{type: type, round: round}, socket) do
    {:noreply,
     socket
     |> assign_live_score(round)
     |> push_event("receive_score", %{type: type})}
  end

  @doc """
  Receives a `%Round.InProgress{}` whenever the outcome changes

  * **From:** `RoundServer` (broadcast)
  * **Topic:** `"room:<slug>"`
  * **Args:** `%{round: %Round.InProgress{}}`
  """
  def handle_outcome_changed(%{round: round}, socket) do
    Logger.info(fn -> "Outcome for current round changed: [#{round.outcome}]" end)

    {:noreply, socket}
  end

  @doc """
  Receives `%{}` representing voters whenever someone sbmits a scores

  * **From:** `RoundServer` (broadcast)
  * **Topic:** `"room:<slug>:score"`
  * **Args:** %{}
  """
  def handle_check_scoring_permission(%{voters: voters}, socket) do
    %{user: %{id: user_id}} = socket.assigns

    socket =
      case Map.has_key?(voters, user_id) do
        true ->
          assign_scoring(socket, :disable)

        false ->
          assign_scoring(socket, :check_user)
      end

    {:noreply, socket}
  end

  def handle_throw_confetti_interaction(%{user: username}, socket) do
    {:noreply,
     socket
     |> push_event("throw_confetti_interaction", %{user: username})}
  end

  defp assign_page_title(socket, title) do
    assign(socket, :page_title, title)
  end

  defp get_list_from_slug(slug) do
    Presence.list(Channels.get_topic(:room, slug))
    |> Enum.map(fn {uuid, %{metas: metas}} -> %{uuid: uuid, metas: metas} end)
  end

  defp schedule_next_tick do
    Process.send_after(self(), :tick, @tick_rate)
  end

  defp assign_scoring(socket, :disable),
    do: assign(socket, :scoring_enabled, %{positive: false, negative: false})

  defp assign_scoring(socket, :check_user) do
    is_enabled = !socket.assigns.visitor
    assign(socket, :scoring_enabled, %{positive: is_enabled, negative: is_enabled})
  end

  defp get_score({positives, negatives}), do: positives - negatives

  defp assign_live_score(socket, 0), do: assign(socket, :live_score, 0)

  defp assign_live_score(socket, round) do
    assign(socket, :live_score, get_score(round.score))
  end
end
