defmodule Serge.Web.Schema.StoryTypes do
  use Absinthe.Schema.Notation

  object :story do
    field :id, :id
    field :team, :team
    field :creator, :user
    field :dev, :user
    field :pm, :user
    field :sort, :float
    field :epic, :string
    field :points, :integer
    field :description, :string
  end
end
