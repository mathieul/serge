defmodule Serge.User do
  use Serge.Web, :model

  schema "users" do
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:uid, :name, :email, :avatar_url])
    |> unique_constraint(:email)
    |> validate_required([:email, :uid])
    |> validate_format(:email, ~r/@/)
  end

  def provider_uid(name, id), do: "#{name}:#{id}"
end
