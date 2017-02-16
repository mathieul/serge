defmodule Serge.Repo.Migrations.CreateTask do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :label, :string
      add :completed_at, :utc_datetime
      add :rank, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:tasks, [:user_id])

  end
end
