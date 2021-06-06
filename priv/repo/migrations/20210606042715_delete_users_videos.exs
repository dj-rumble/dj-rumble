defmodule DjRumble.Repo.Migrations.DeleteUsersVideos do
  use Ecto.Migration

  def down do
    drop table(:users_videos)
  end
end
