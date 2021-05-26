defmodule DjRumbleWeb.Live.Components.Playlist do
  @moduledoc """
  Responsible for showing the queue of videos to be played
  """

  use DjRumbleWeb, :live_component

  def update(%{videos: videos} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:videos, Enum.with_index(videos))}
  end

  def parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
