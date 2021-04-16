defmodule DjRumble.Repo.Migrations.CreateRoomsVideos do
  use Ecto.Migration

  def change do
    create table(:rooms_videos) do
      add :room_id, references(:rooms, on_delete: :nothing)
      add :video_id, references(:videos, on_delete: :nothing)

      timestamps()
    end

    create index(:rooms_videos, [:room_id])
    create index(:rooms_videos, [:video_id])
  end
end
