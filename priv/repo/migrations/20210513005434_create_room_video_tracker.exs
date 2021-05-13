defmodule DjRumble.Repo.Migrations.CreateRoomVideoTracker do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :video_tracker, :string, default: ""
    end
  end
end
