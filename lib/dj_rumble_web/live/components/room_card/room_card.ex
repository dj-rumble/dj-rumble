defmodule DjRumbleWeb.Live.Components.RoomCard do
  @moduledoc """
  Responsible for showing a room card
  """

  use DjRumbleWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:current_round, %{video: nil, added_by: nil})
     |> assign(:room, nil)
     |> assign(:status, :idle)
     |> assign(:videos, [])}
  end

  @impl true
  def update(assigns, socket) do
    %{current_round: current_round, room: room, status: status, videos: videos} = assigns

    {:ok,
     socket
     |> assign(:current_round, current_round)
     |> assign(:room, room)
     |> assign(:status, status)
     |> assign(:videos, videos)
     |> assign(assigns)}
  end

  defp is_playing(status) do
    status == :playing
  end
end
