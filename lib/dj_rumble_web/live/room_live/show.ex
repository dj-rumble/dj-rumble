defmodule DjRumbleWeb.RoomLive.Show do
  @moduledoc """
  Responsible for controlling the Show room live view
  """

  use DjRumbleWeb, :live_view

  alias DjRumble.Repo
  alias DjRumble.Rooms
  alias DjRumbleWeb.Presence
  alias Faker

  def get_list_from_slug(slug) do
    Presence.list("room:#{slug}")
    |> Enum.map(fn {uuid, %{metas: metas}} -> %{uuid: uuid, metas: metas} end)
  end

  @impl true
  def mount(%{"slug" => slug} = params, session, socket) do
    case Rooms.get_room_by_slug(slug) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "That room does not exist.")
         |> push_redirect(to: Routes.room_index_path(socket, :index))}

      room ->
        %{assigns: %{user: user}} = socket = assign_defaults(socket, params, session)
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
         |> assign(:room, room)
         |> assign(:videos, room.videos)
         |> assign(:index_playing, index_playing)
         |> assign(:connected_users, connected_users)}
    end
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_is_ready", _params, socket) do
    case Enum.at(socket.assigns.videos, 0) do
      nil ->
        {:noreply, socket}

      video ->
        {:noreply,
         socket
         |> assign(:page_title, page_title(video))
         |> push_event("receive_player_state", %{
           videoId: video.video_id,
           shouldPlay: true,
           time: 0
         })}
    end
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
  def handle_info(
        %{event: "presence_diff", payload: %{joins: _joins, leaves: _leaves}},
        %{assigns: %{room: %{slug: slug}}} = socket
      ) do
    connected_users = get_list_from_slug(slug)

    {:noreply, assign(socket, :connected_users, connected_users)}
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"

  defp page_title(video) do
    case video do
      nil -> ""
      _ -> video.title
    end
  end

  def handle_info({:add_to_queue, params}, %{assigns: assigns} = socket) do
    %{video_to_add: selected_video} = params

    %{videos: videos, room: room} = assigns

    {:ok, new_video} =
      Rooms.create_video(%{
        channel_title: room.slug,
        description: selected_video.description,
        img_url: selected_video.thumbnails["default"]["url"],
        img_width: "#{selected_video.thumbnails["default"]["width"]}",
        img_height: "#{selected_video.thumbnails["default"]["height"]}",
        title: selected_video.title,
        video_id: selected_video.video_id
      })

    Rooms.create_room_video(%{room_id: room.id, video_id: new_video.id})

    videos = videos ++ [new_video]

    {:noreply,
     socket
     |> assign(:videos, videos)}
  end
end
