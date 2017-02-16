defmodule Serge.Repo.Migrations.CreateTask do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :label, :string, null: false
      add :completed_at, :utc_datetime
      add :rank, :integer, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end
    create index(:tasks, [:user_id])

  end
end
