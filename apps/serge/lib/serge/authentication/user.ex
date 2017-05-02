defmodule Serge.Authentication.User do
  use Ecto.Schema
  use Timex.Ecto.Timestamps

  schema "users" do
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string

    has_many :teams, Serge.Scrumming.Team, foreign_key: :owner_id

    timestamps()
  end
end
