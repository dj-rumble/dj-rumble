defmodule DjRumble.Notifications do
  @moduledoc """
  A module responsible for creating notification structures
  """

  def create(video) do
    %{title: video_title, img_url: img_url} = video

    notification_title = "DjRumble"
    body = "Now playing: #{video_title}"

    %{body: body, title: notification_title, img: img_url, tag: "playing-video"}
  end
end
