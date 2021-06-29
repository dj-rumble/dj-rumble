defmodule DjRumbleWeb.AlbumCoverGridView do
  use DjRumbleWeb, :view

  def get_video_chunks(videos) do
    Enum.take(videos, 4)
    |> Enum.zip(["rounded-tl-md", "rounded-tr-md", "rounded-bl-md", "rounded-br-md"])
    |> Enum.chunk_every(2)
  end
end
