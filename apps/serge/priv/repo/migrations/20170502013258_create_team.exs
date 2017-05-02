defmodule Serge.Repo.Migrations.CreateTeam do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :owner_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:teams, [:owner_id])
  end
end
