defmodule DjRumbleWeb.RoomLive.Index do
  @moduledoc """
  Responsible for controlling the Room list live view
  """
  use DjRumbleWeb, :live_view

  alias DjRumble.Repo
  alias DjRumble.Rooms
  alias DjRumble.Rooms.Room

  @impl true
  def mount(params, session, socket) do
    socket = assign_defaults(socket, params, session)
    rooms = list_rooms() |> Enum.map(fn room -> Repo.preload(room, [:videos]) end)
    {:ok, assign(socket, :rooms, rooms)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Rooms.get_room!(id))
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

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Rooms.get_room!(id)
    {:ok, _} = Rooms.delete_room(room)

    {:noreply, assign(socket, :rooms, list_rooms())}
  end

  def handle_event("redirect_room", %{"slug" => slug}, socket) do
    {:noreply,
     socket
     |> redirect(to: Routes.room_show_path(socket, :show, slug))}
  end

  defp list_rooms do
    Rooms.list_rooms()
  end
end
