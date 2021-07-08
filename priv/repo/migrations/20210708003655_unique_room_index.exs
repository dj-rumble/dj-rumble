defmodule DjRumble.Repo.Migrations.UniqueRoomIndex do
  use Ecto.Migration

  def change do
    create unique_index(:rooms, :slug)
  end
end
