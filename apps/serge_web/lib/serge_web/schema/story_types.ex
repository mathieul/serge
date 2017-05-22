defmodule Serge.Web.Schema.StoryTypes do
  use Absinthe.Schema.Notation

  alias Serge.Repo

  object :story do
    field :id, :id
    field :sort, :float
    field :epic, :string
    field :points, :integer
    field :description, :string

    field :team, :team do
      resolve fn story, _args, _ctx ->
        {:ok, Repo.preload(story, :team).team}
      end
    end

    field :creator, :user do
      resolve fn story, _args, _ctx ->
        {:ok, Repo.preload(story, :creator).creator}
      end
    end

    field :dev, :user do
      resolve fn story, _args, _ctx ->
        {:ok, Repo.preload(story, :dev).dev}
      end
    end

    field :pm, :user do
      resolve fn story, _args, _ctx ->
        {:ok, Repo.preload(story, :pm).pm}
      end
    end
  end
end
