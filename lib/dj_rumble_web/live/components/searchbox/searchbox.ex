defmodule DjRumbleWeb.Live.Components.Searchbox do
  @moduledoc """
  Responsible for making querying the Youtube API, displaying the results and
  adding a selected video to the room playlist.
  """

  use DjRumbleWeb, :live_component

  alias DjRumble.Rooms.Video

  require Logger

  @impl true
  def update(assigns, socket) do
    _search_result = [
      {%DjRumble.Rooms.Video{
         #  __meta__: #Ecto.Schema.Metadata<:built, "videos">,
         channel_title: "Vulf",
         description:
           "0:00 The Sweet Science 2:18 Tee Time 4:19 Animal Spirits 7:55 Cory Wong 12:38 My First Car 15:42 Daddy, He Got a Tesla 20:18 Arena Meditation 24:22 ...",
         id: nil,
         img_height: "90",
         img_url: "https://i.ytimg.com/vi/rv4wf7bzfFE/default.jpg",
         img_width: "120",
         inserted_at: nil,
         #  rooms: #Ecto.Association.NotLoaded<association :rooms is not loaded>,
         title: "VULFPECK /// Live at Madison Square Garden",
         updated_at: nil,
         #  users: #Ecto.Association.NotLoaded<association :users is not loaded>,
         video_id: "rv4wf7bzfFE"
       }, 0},
      {%DjRumble.Rooms.Video{
         #  __meta__: #Ecto.Schema.Metadata<:built, "videos">,
         channel_title: "Vulf",
         description:
           "VULFPECK /// Back Pocket (Live at Madison Square Garden) buy on vinyl → https://vuuulf.com/msg.",
         id: nil,
         img_height: "90",
         img_url: "https://i.ytimg.com/vi/UZPX9KQbwsg/default.jpg",
         img_width: "120",
         inserted_at: nil,
         #  rooms: #Ecto.Association.NotLoaded<association :rooms is not loaded>,
         title: "VULFPECK /// Back Pocket (Live at Madison Square Garden)",
         updated_at: nil,
         #  users: #Ecto.Association.NotLoaded<association :users is not loaded>,
         video_id: "UZPX9KQbwsg"
       }, 1},
      {%DjRumble.Rooms.Video{
         #  __meta__: #Ecto.Schema.Metadata<:built, "videos">,
         channel_title: "Larry Rulz FORE!",
         description:
           "Recorded on September 28, 2019 at MSG in New York, NY. Setlist: 0:00 intro 0:45 Mike Winograd clarinet solo - The Sweet Science 3:00 Tee Time - Jack ...",
         id: nil,
         img_height: "90",
         img_url: "https://i.ytimg.com/vi/1Ovz3Zc5fEY/default.jpg",
         img_width: "120",
         inserted_at: nil,
         #  rooms: #Ecto.Association.NotLoaded<association :rooms is not loaded>,
         title: "Vulfpeck - Madison Square Garden - September 28, 2019",
         updated_at: nil,
         #  users: #Ecto.Association.NotLoaded<association :users is not loaded>,
         video_id: "1Ovz3Zc5fEY"
       }, 2},
      {%DjRumble.Rooms.Video{
         #  __meta__: #Ecto.Schema.Metadata<:built, "videos">,
         channel_title: "Vulf",
         description:
           "VULFPECK /// Dean Town (Live at Madison Square Garden) buy vinyl first pressing at https://vulfpeck.bandcamp.com/",
         id: nil,
         img_height: "90",
         img_url: "https://i.ytimg.com/vi/rhxQoDlt2AU/default.jpg",
         img_width: "120",
         inserted_at: nil,
         #  rooms: #Ecto.Association.NotLoaded<association :rooms is not loaded>,
         title: "VULFPECK /// Dean Town (Live at Madison Square Garden)",
         updated_at: nil,
         #  users: #Ecto.Association.NotLoaded<association :users is not loaded>,
         video_id: "rhxQoDlt2AU"
       }, 3},
      {%DjRumble.Rooms.Video{
         #  __meta__: #Ecto.Schema.Metadata<:built, "videos">,
         channel_title: "ra punkabest",
         description: "Superfunk.",
         id: nil,
         img_height: "90",
         img_url: "https://i.ytimg.com/vi/y8GbpZN071M/default.jpg",
         img_width: "120",
         inserted_at: nil,
         #  rooms: #Ecto.Association.NotLoaded<association :rooms is not loaded>,
         title: "Vulfpeck - Cory Wong - Live at Madison Square Garden",
         updated_at: nil,
         #  users: #Ecto.Association.NotLoaded<association :users is not loaded>,
         video_id: "y8GbpZN071M"
       }, 4}
    ]

    {:ok,
     socket
     |> assign(:search_results, [])
     |> assign(:search_query, "")
     |> assign(:opened, true)
     |> assign(:initial_position, "right-0")
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
    opts = [maxResults: 20]

    search_result =
      case Tubex.Video.search_by_query(query, opts) do
        {:ok, search_result, _pag_opts} ->
          Enum.map(search_result, &Video.from_tubex(&1))

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
     |> assign(:state, "OPEN")
     |> push_event("receive_search_completed_signal", %{})}
  end

  @impl true
  def handle_event("add_to_queue", selected_video, socket) do
    %{assigns: %{search_results: search_results}} = socket

    {selected_video, _index} =
      Enum.find(
        search_results,
        fn {_search, index} ->
          {selected_video, _} = Integer.parse(selected_video["video_id"])
          index == selected_video
        end
      )

    :ok = Process.send(self(), {:create_round, selected_video}, [])

    {:noreply, socket}
  end

  defp render_button("add", video_index, assigns) do
    id = "search-element-button-#{video_index + 1}"

    props = %{
      classes: "
        search-control-enabled clickeable
        transition duration-500 ease-in-out
      ",
      click_event: "add_to_queue",
      icon_classes: "show-add-button",
      id: id,
      value: video_index
    }

    render_button(props, assigns)
  end

  defp render_button(
         %{
           classes: classes,
           id: id,
           icon_classes: icon_classes,
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
        <%= render_svg("add", "h-8 w-8 #{icon_classes}") %>
      </a>
    """
  end

  defp render_svg(icon, classes) do
    PhoenixInlineSvg.Helpers.svg_image(DjRumbleWeb.Endpoint, "buttons/#{icon}", class: classes)
  end

  defp parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
