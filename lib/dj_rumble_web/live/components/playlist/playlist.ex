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

    videos_users =
      next_rounds
      |> Enum.map(fn %{video: video, user: user} -> {video, user.username} end)
      |> Enum.with_index()

    {:ok,
     socket
     |> assign(:room_server, room_server)
     |> assign(:videos_users, videos_users)}
  end

  defp get_card_class(0), do: "bg-gray-700"
  defp get_card_class(_), do: "bg-gray-800"

  defp get_notice_by_video_position(_video_user, 0, assigns) do
    ~L"""
    <span class="animate-pulse">Next coming!</span>
    """
  end

  defp get_notice_by_video_position(_video_user, _, assigns) do
    ~L"""
    <span></span>
    """
  end
end
