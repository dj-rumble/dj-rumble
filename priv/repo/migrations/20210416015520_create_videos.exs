defmodule DjRumble.Repo.Migrations.CreateVideos do
  use Ecto.Migration

  def change do
    create table(:videos) do
      add :video_id, :string
      add :title, :string
      add :description, :string
      add :channel_title, :string
      add :img_url, :string
      add :img_height, :string
      add :img_width, :string

      timestamps()
    end

  end
end
