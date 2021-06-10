defmodule DjRumble.CollectionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `DjRumble.Collections` context.
  """
  alias DjRumble.Collections
  alias DjRumble.Repo
  alias DjRumble.Rooms

  import DjRumble.RoomsFixtures

  def user_room_video_fixture(
        %{room: room, video: video, user: user},
        opts \\ %{preload_attrs: []}
      ) do
    {:ok, user_room_video} =
      Collections.create_user_room_video(%{room_id: room.id, video_id: video.id, user_id: user.id})

    _user_room_video = Repo.preload(user_room_video, opts.preload_attrs)
  end
end
