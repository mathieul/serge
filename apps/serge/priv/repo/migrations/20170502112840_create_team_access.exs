defmodule Serge.Repo.Migrations.CreateTeamAccess do
  use Ecto.Migration

  def up do
    AccessKindEnum.create_type
    create table(:team_accesses) do
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :team_id, references(:teams, on_delete: :nothing), null: false
      add :kind, :access_kind, null: false

      timestamps()
    end

    create index(:team_accesses, [:user_id, :team_id])
  end

  def down do
    drop table(:team_accesses)
    AccessKindEnum.drop_type
  end
end
