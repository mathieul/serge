defmodule Serge.Repo.Migrations.AddSentAtToTeamAccesses do
  use Ecto.Migration

  def change do
    alter table(:team_accesses) do
      add :sent_at, :utc_datetime
    end
  end
end
