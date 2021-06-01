defmodule DjRumbleWeb.Live.Components.Playlist do
  @moduledoc """
  Responsible for showing the queue of videos to be played
  """

  use DjRumbleWeb, :live_component

  def update(%{next_rounds: next_rounds}, socket) do
    videos =
      next_rounds
      |> Enum.map(fn %{video: video} -> video end)
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(:videos, videos)}
  end

  defp parse_int(str) do
    {int, _} = Integer.parse(str)
    int
  end
end
