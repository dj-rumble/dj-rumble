defmodule DjRumble.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :name, :string
      add :slug, :string

      timestamps()
    end
  end
end
