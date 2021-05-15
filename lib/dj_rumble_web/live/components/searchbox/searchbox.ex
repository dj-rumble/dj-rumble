defmodule DjRumbleWeb.Live.Components.Searchbox do
  @moduledoc """
  Responsible for making querying the Youtube API, displaying the results and
  adding a selected video to the room playlist.
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms

  require Logger

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:search_results, [])
     |> assign(:search_query, "")
     |> assign(assigns)}
  end

  @impl true
  def handle_event("search", %{"search_field" => search_field}, socket) do
    {:noreply, assign(socket, :search_query, search_field["query"])}
  end

  @impl true
  def handle_event(
        "submit",
        _params,
        %{assigns: %{search_query: query}} = socket
      ) do
    opts = [maxResults: 5]

    search_result =
      case Tubex.Video.search_by_query(query, opts) do
        {:ok, search_result, _pag_opts} ->
          search_result

        {:error, %{"error" => %{"errors" => errors}}} ->
          for error <- errors do
            Logger.error(error["message"])
          end

          []
      end

    search_result =
      search_result
      |> Enum.with_index()

    {:noreply,
     socket
     |> assign(:search_results, search_result)
     |> push_event("receive_search_completed_signal", %{})}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{
      assigns: %{
        room: room,
        search_results: search_results,
        slug: slug
      }
    } = socket

    {selected_video, _index} =
      Enum.find(
        search_results,
        fn {_search, index} ->
          {selected_video, _} = Integer.parse(selected_video["video_id"])
          index == selected_video
        end
      )

    {:ok, new_video} =
      Rooms.create_video(%{
        channel_title: selected_video.channel_title,
        description: selected_video.description,
        img_url: selected_video.thumbnails["default"]["url"],
        img_width: "#{selected_video.thumbnails["default"]["width"]}",
        img_height: "#{selected_video.thumbnails["default"]["height"]}",
        title: selected_video.title,
        video_id: selected_video.video_id
      })

    {:ok, _room_video} = Rooms.create_room_video(%{room_id: room.id, video_id: new_video.id})

    Phoenix.PubSub.broadcast(
      DjRumble.PubSub,
      "room:" <> slug,
      {:add_to_queue,
       %{
         new_video: new_video
       }}
    )

    {:noreply, socket}
  end

  defp render_button("add", video_index, assigns) do
    id = "search-element-button-#{video_index + 1}"

    props = %{
      classes: "search-control-enabled clickeable add-button",
      click_event: "add_to_queue",
      id: id,
      value: video_index
    }

    render_button(props, assigns)
  end

  defp render_button(
         %{
           classes: classes,
           id: id,
           value: value,
           click_event: click_event
         },
         assigns
       ) do
    ~L"""
      <a
        class="<%= classes %>"
        id="<%= id %>"
        phx-click="<%= click_event %>"
        phx-target="<%= assigns %>"
        phx-value-video_id="<%= value %>"
      >
        +
      </a>
    """
  end
end