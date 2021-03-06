defmodule Serge.Repo.Migrations.AddTokenAndTimestampsToTeamAccesses do
  use Ecto.Migration

  def change do
    alter table(:team_accesses) do
      add :email,       :string
      add :token,       :string,       null: false
      add :expires_at,  :utc_datetime, null: false
      add :accepted_at, :utc_datetime
      add :rejected_at, :utc_datetime

      modify :user_id,  :id, null: true
    end
  end
end
