defmodule Serge.Authentication.User do
  use Ecto.Schema
  use Timex.Ecto.Timestamps

  schema "users" do
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string

    timestamps()
  end
end
