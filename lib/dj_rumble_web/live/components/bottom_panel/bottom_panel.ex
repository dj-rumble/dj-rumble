defmodule DjRumbleWeb.Live.Components.BottomPanel do
  @moduledoc """
  Responsible for showing a bottom panel
  """

  use DjRumbleWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("fullscreen", _params, socket) do
    {:noreply,
     socket
     |> push_event("fullscreen", %{})}
  end
end
