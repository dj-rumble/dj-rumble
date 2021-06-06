defmodule DjRumble.Repo.Migrations.CreateUsersRoomsVideos do
  use Ecto.Migration

  def change do
    create table(:users_rooms_videos) do
      add :room_id, references(:rooms, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create index(:users_rooms_videos, [:room_id])
    create index(:users_rooms_videos, [:user_id])
    create index(:users_rooms_videos, [:video_id])
  end
end
