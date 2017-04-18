defmodule Serge.Repo.Migrations.CreateTask do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :label, :string, null: false
      add :rank, :integer, null: false
      add :user_id, references(:users, on_delete: :nothing), null: false
      add :completed_on, :date
      add :scheduled_on, :date

      timestamps()
    end
    create index(:tasks, [:user_id])
  end
end
