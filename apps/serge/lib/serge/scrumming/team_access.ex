defmodule Serge.Scrumming.TeamAccess do
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query

  schema "team_accesses" do
    belongs_to :user, Serge.Authentication.User
    belongs_to :team, Serge.Scrumming.Team
    field :kind, AccessKindEnum

    timestamps()
  end

  ###
  # Queries
  ###

  def for_user_id(scope \\ __MODULE__, user_id) do
    from(t in scope, where: t.user_id == ^user_id)
  end
end
