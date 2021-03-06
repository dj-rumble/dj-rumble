defmodule DjRumbleWeb.Components.Modal do
  @moduledoc """
  Responsible for showing a generic modal window
  """
  use DjRumbleWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok, assign(socket, state: "CLOSED")}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("open", _, socket) do
    {:noreply,
     socket
     |> assign(:state, "OPEN")}
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply,
     socket
     |> assign(:state, "CLOSED")}
  end
end
