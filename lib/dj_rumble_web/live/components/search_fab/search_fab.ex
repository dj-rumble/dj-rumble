defmodule DjRumbleWeb.Live.Components.SearchFab do
  @moduledoc """
  Responsible for showing the searchbox
  """

  use DjRumbleWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("open_search_modal", _, socket) do
    {:noreply, socket}
  end
end
