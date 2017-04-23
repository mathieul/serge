defmodule Activity.Repo.Migrations.CreateEvent do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:events, engine: :set) do
      add :id,          :integer
      add :user_name,   :string
      add :avatar_url,  :string
      add :message,     :string

      timestamps()
    end
  end
end
