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
end
