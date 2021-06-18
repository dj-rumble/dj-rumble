defmodule DjRumble.Repo.Migrations.DeleteRoomTracker do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      remove :video_tracker
    end
  end
end
