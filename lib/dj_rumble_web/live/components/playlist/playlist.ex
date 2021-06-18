defmodule DjRumbleWeb.Live.Components.Playlist do
  @moduledoc """
  Responsible for showing the queue of videos to be played
  """

  use DjRumbleWeb, :live_component

  def update(assigns, socket) do
    %{
      next_rounds: next_rounds,
      room_server: room_server
    } = assigns

    videos =
      next_rounds
      |> Enum.map(fn %{video: video} -> video end)
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(:room_server, room_server)
     |> assign(:videos, videos)}
  end
end
