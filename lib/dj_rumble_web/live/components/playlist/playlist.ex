defmodule DjRumbleWeb.Live.Components.Playlist do
  @moduledoc """
  Responsible for showing the queue of videos to be played
  """

  use DjRumbleWeb, :live_component

  def mount(socket) do
    {:ok, assign(socket, :videos_users, [])}
  end

  def update(assigns, socket) do
    %{
      next_rounds: next_rounds,
      room_server: room_server
    } = assigns

    {:ok,
     socket
     |> assign(:room_server, room_server)
     |> assign_video_users(next_rounds)}
  end

  defp assign_video_users(socket, next_rounds) do
    %{videos_users: videos_users} = socket.assigns

    current_videos_ids = Enum.map(videos_users, fn {video, _user, _state} -> video.video_id end)

    videos_users =
      Enum.map(next_rounds, fn %{video: video, user: user} ->
        classes =
          case Enum.member?(current_videos_ids, video.video_id) do
            true -> ""
            false -> "animated fadeIn"
          end

        {video, user.username, classes}
      end)

    assign(socket, :videos_users, videos_users)
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
