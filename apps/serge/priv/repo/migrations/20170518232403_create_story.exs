defmodule Serge.Repo.Migrations.CreateStory do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :creator_id, references(:users, on_delete: :nothing), null: false
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :dev_id, references(:users, on_delete: :nothing), null: true
      add :pm_id, references(:users, on_delete: :nothing), null: true
      add :sort, :float, null: false, default: 10.0
      add :epic, :string
      add :points, :integer, null: false, default: 0
      add :description, :string, null: false

      timestamps()
    end
  end
end
