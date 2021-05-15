defmodule DjRumbleWeb.Live.Components.Searchbox do
  @moduledoc """
  Responsible for making queries to Youtube API, displaying the results and adding a selected video to the room playlist.
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    init =
      [
        %Tubex.Video{
          channel_id: "UCebyVVGrutTKqEivCs0txpw",
          channel_title: "erwinorb",
          description:
            "Mark Farina - Mushroom Jazz 2 \"Then Came You\" - Euphonic feat. Kevin Yost \"Sandworms\" - Andy Caldwell vs. Darkhorse \"Piano Grand\" - Tony D \"That Time of ...",
          etag: nil,
          playlist_id: nil,
          published_at: "2014-07-10T20:38:13Z",
          thumbnails: %{
            "default" => %{
              "height" => 90,
              "url" => "https://i.ytimg.com/vi/f6k0FlHGrZE/default.jpg",
              "width" => 120
            },
            "high" => %{
              "height" => 360,
              "url" => "https://i.ytimg.com/vi/f6k0FlHGrZE/hqdefault.jpg",
              "width" => 480
            },
            "medium" => %{
              "height" => 180,
              "url" => "https://i.ytimg.com/vi/f6k0FlHGrZE/mqdefault.jpg",
              "width" => 320
            }
          },
          title: "Mark Farina - Mushroom Jazz 2",
          video_id: "f6k0FlHGrZE"
        },
        %Tubex.Video{
          channel_id: "UCC1stBxjEqHYiDo5BRm-7OQ",
          channel_title: "INMATE EARTH music",
          description: "Mushroom Jazz Playlist on this Channel.",
          etag: nil,
          playlist_id: nil,
          published_at: "2018-04-06T12:59:44Z",
          thumbnails: %{
            "default" => %{
              "height" => 90,
              "url" => "https://i.ytimg.com/vi/eec_zlvlbh4/default.jpg",
              "width" => 120
            },
            "high" => %{
              "height" => 360,
              "url" => "https://i.ytimg.com/vi/eec_zlvlbh4/hqdefault.jpg",
              "width" => 480
            },
            "medium" => %{
              "height" => 180,
              "url" => "https://i.ytimg.com/vi/eec_zlvlbh4/mqdefault.jpg",
              "width" => 320
            }
          },
          title: "Mushroom Jazz 2 trippy HD Visuals",
          video_id: "eec_zlvlbh4"
        },
        %Tubex.Video{
          channel_id: "UCJ8aupfy69gF64znpYL7T9Q",
          channel_title: "Francisco Criollo",
          description:
            "Euphonic* Feat. Kevin Yost Then Came You 4:03 Andy Caldwell v. Darkhorse Sandworms 3:06 Tony D Piano Grand 2:56 Jaywalkers That Time Of Day (Again) ...",
          etag: nil,
          playlist_id: nil,
          published_at: "2015-01-27T01:20:56Z",
          thumbnails: %{
            "default" => %{
              "height" => 90,
              "url" => "https://i.ytimg.com/vi/TW9ozkvCULM/default.jpg",
              "width" => 120
            },
            "high" => %{
              "height" => 360,
              "url" => "https://i.ytimg.com/vi/TW9ozkvCULM/hqdefault.jpg",
              "width" => 480
            },
            "medium" => %{
              "height" => 180,
              "url" => "https://i.ytimg.com/vi/TW9ozkvCULM/mqdefault.jpg",
              "width" => 320
            }
          },
          title: "Mark Farina-Mushroom Jazz vol 2",
          video_id: "TW9ozkvCULM"
        },
        %Tubex.Video{
          channel_id: "UCdlYbLYOaa64dUzJ58aaRTw",
          channel_title: "Matt Katar",
          description:
            "\"Mushroom Jazz 4\" by DJ Mark Farina was a mix compilation released on 04 November 2002 through OM Records. Listen to the other Mushroom Jazzes: 1: ...",
          etag: nil,
          playlist_id: nil,
          published_at: "2014-10-25T16:46:48Z",
          thumbnails: %{
            "default" => %{
              "height" => 90,
              "url" => "https://i.ytimg.com/vi/u5u6l4IB0WE/default.jpg",
              "width" => 120
            },
            "high" => %{
              "height" => 360,
              "url" => "https://i.ytimg.com/vi/u5u6l4IB0WE/hqdefault.jpg",
              "width" => 480
            },
            "medium" => %{
              "height" => 180,
              "url" => "https://i.ytimg.com/vi/u5u6l4IB0WE/mqdefault.jpg",
              "width" => 320
            }
          },
          title: "Mark Farina - Mushroom Jazz 4 [Full Mixtape]",
          video_id: "u5u6l4IB0WE"
        },
        %Tubex.Video{
          channel_id: "UCdlYbLYOaa64dUzJ58aaRTw",
          channel_title: "Matt Katar",
          description:
            "\"Mushroom Jazz 3\" by DJ Mark Farina was a mix compilation released on 20 March 2001 through OM Records. Listen to the other Mushroom Jazzes: 1: ...",
          etag: nil,
          playlist_id: nil,
          published_at: "2014-11-01T21:05:47Z",
          thumbnails: %{
            "default" => %{
              "height" => 90,
              "url" => "https://i.ytimg.com/vi/Y9jp7UrBtbM/default.jpg",
              "width" => 120
            },
            "high" => %{
              "height" => 360,
              "url" => "https://i.ytimg.com/vi/Y9jp7UrBtbM/hqdefault.jpg",
              "width" => 480
            },
            "medium" => %{
              "height" => 180,
              "url" => "https://i.ytimg.com/vi/Y9jp7UrBtbM/mqdefault.jpg",
              "width" => 320
            }
          },
          title: "Mark Farina - Mushroom Jazz 3 [Full Mixtape]",
          video_id: "Y9jp7UrBtbM"
        }
      ]
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(:search_results, init)
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
    # video_queue = Enum.map(video_queue, fn {v, _} -> v end)
    opts = [maxResults: 5]

    search_result =
      case Tubex.Video.search_by_query(query, opts) do
        {:ok, search_result, _pag_opts} ->
          search_result

        {:error, %{"error" => %{"errors" => errors}}} ->
          for error <- errors do
            # Logger.error(error["message"])
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

    Phoenix.PubSub.broadcast(
      DjRumble.PubSub,
      "room:" <> slug,
      {:add_to_queue,
       %{
         video_to_add: selected_video
       }}
    )

    {:noreply, socket}
  end

  defp render_button("add", video_index, assigns) do
    id = "search-element-button-#{video_index + 1}"

    props = %{
      classes: "search-control-enabled clickeable add-button",
      click_event: "add_to_queue",
      icon: "icons/search/add",
      icon_classes: "show-add-button",
      id: id,
      value: video_index
    }

    render_button(props, assigns)
  end

  defp render_button(
         %{
           classes: classes,
           icon: icon,
           icon_classes: icon_classes,
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

  defp render_svg(icon, classes) do
    PhoenixInlineSvg.Helpers.svg_image(DjRumbleWeb.Endpoint, icon, class: classes)
  end
end
