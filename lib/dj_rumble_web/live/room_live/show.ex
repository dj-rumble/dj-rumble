defmodule DjRumbleWeb.RoomLive.Show do
  use DjRumbleWeb, :live_view

  alias DjRumble.Repo
  alias DjRumble.Rooms
  alias DjRumbleWeb.Presence
  alias Faker

  def get_list_from_slug(slug) do
    Presence.list("room:#{slug}")
            |> Enum.map(fn {uuid, %{metas: metas}} -> %{uuid: uuid, metas: metas} end)
  end

  def create_random_name() do
    adjectives = [
      fn -> Faker.Superhero.descriptor end,
      fn -> Faker.Pizza.cheese end,
      fn -> Faker.Pizza.style end,
      fn -> Faker.Commerce.product_name_material end,
      fn -> Faker.Cannabis.strain end,
      fn -> Faker.Commerce.product_name_adjective end,
    ]
    nouns = [
      fn -> Faker.StarWars.character end,
      fn -> Faker.Pokemon.name end,
      fn -> Faker.Food.ingredient end,
      fn -> Faker.Superhero.name end,
    ]
    descriptor  = Enum.at(adjectives, Enum.random(0..length(adjectives)-1))
    name = Enum.at(nouns, Enum.random(0..length(nouns)-1))
    "#{descriptor.()} #{name.()}"
  end

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Rooms.get_room_by_slug(slug) do
      nil ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.room_index_path(socket, :index))
        }
      room ->
        video = Enum.at(Repo.preload(room, [:videos]).videos, 0)

        # before subscribing, let's get the current_reader_count
        topic = "room:#{slug}"
        connected_users = get_list_from_slug(slug)

        # Subscribe to the topic
        DjRumbleWeb.Endpoint.subscribe(topic)

        # Track changes to the topic
        Presence.track(
          self(),
          topic,
          socket.id,
          %{ username: create_random_name() }
        )

        {:ok,
          socket
          |> assign(:page_title, page_title(video.title))
          |> assign(:room, room)
          |> assign(:video, video)
          |> assign(:connected_users, connected_users)}
    end
  end



  @impl true
  def handle_params(_params, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("player_is_ready", _params, socket) do
    case Map.has_key?(socket.assigns, :video) do
      false -> {:noreply, socket}
      true ->
        %{video: video} = socket.assigns
        {:noreply,
          socket
          |> push_event("receive_player_state", %{videoId: video.video_id, shouldPlay: true, time: 0})}
    end
  end

  @impl true
  def handle_info(
        %{event: "presence_diff", payload: %{joins: _joins, leaves: _leaves}},
        %{assigns: %{room: %{slug: slug}}} = socket
      ) do

    connected_users = get_list_from_slug(slug)

    {:noreply,
      assign(socket, :connected_users, connected_users) }
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
  defp page_title(title), do: title
end
