defmodule Serge.Schema.Types do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string
  end
end
