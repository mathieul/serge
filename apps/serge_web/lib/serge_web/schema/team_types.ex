defmodule Serge.Web.Schema.TeamTypes do
  use Absinthe.Schema.Notation

  object :team do
    field :id, :id
    field :name, :string
    field :description, :string
  end
end
