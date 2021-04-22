defmodule DjRumbleWeb.RoomLive.Show do
  use DjRumbleWeb, :live_view

  alias DjRumble.Rooms

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"slug" => slug}, _, socket) do
    room = Rooms.get_room_by_slug(slug)
    case room do
      nil ->
        {:noreply,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.room_index_path(socket, :index))
        }
      room ->
        {:noreply,
          socket
          |> assign(:page_title, page_title(socket.assigns.live_action))
          |> assign(:room, room)}
    end
  end

  defp page_title(:show), do: "Show Room"
  defp page_title(:edit), do: "Edit Room"
end
