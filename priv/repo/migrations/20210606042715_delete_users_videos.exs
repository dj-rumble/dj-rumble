defmodule DjRumble.Repo.Migrations.DeleteUsersVideos do
  use Ecto.Migration

  def change do
    drop table(:users_videos)
  end
end
