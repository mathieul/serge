defmodule Serge.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :uid,         :string
      add :email,       :string
      add :name,        :string
      add :avatar_url,  :string

      timestamps()
    end

    create unique_index(:users, [:uid])
  end
end
