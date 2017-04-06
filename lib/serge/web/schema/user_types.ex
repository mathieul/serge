defmodule Serge.Web.Schema.UserTypes do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string
    field :tasks, list_of(:task)
  end
end
