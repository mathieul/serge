defmodule Serge.Scrumming.Story do
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query

  schema "stories" do
    field :sort,        :float
    field :epic,        :string
    field :points,      :integer
    field :description, :string

    belongs_to :creator,  Serge.Authentication.User
    belongs_to :team,     Serge.Scrumming.Team
    belongs_to :dev,      Serge.Authentication.User
    belongs_to :pm,       Serge.Authentication.User

    timestamps()
  end

  ###
  # Queries
  ###

  def for_team_id(scope \\ __MODULE__, team_id) do
    from(story in scope, where: story.team_id == ^team_id)
  end

  def ordered_by_sort_and_inserted_at(scope \\ __MODULE__) do
    from(story in scope, order_by: [asc: :sort, asc: :inserted_at])
  end
end
