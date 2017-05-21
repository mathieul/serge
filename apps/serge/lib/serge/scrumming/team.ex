defmodule Serge.Scrumming.Team do
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query
  alias Serge.Scrumming.TeamAccess

  schema "teams" do
    field :name,              :string
    field :description,       :string
    field :count_pending,     :integer, virtual: true
    field :count_accepted,    :integer, virtual: true
    field :count_rejected,    :integer, virtual: true

    belongs_to :owner,        Serge.Authentication.User
    has_many :team_accesses,  TeamAccess
    has_many :members,        through: [:team_accesses, :user]

    timestamps()
  end

  ###
  # Queries
  ###

  def for_owner_id(scope \\ __MODULE__, owner_id) do
    from(t in scope, where: t.owner_id == ^owner_id)
  end

  def ordered_by_name(scope \\ __MODULE__) do
    from(t in scope, order_by: [asc: :name])
  end

  def with_team_access_counts(scope \\ __MODULE__) do
    pending_access = TeamAccess.pending |> TeamAccess.count |> subquery
    accepted_access = TeamAccess.accepted |> TeamAccess.count |> subquery
    rejected_access = TeamAccess.rejected |> TeamAccess.count |> subquery
    from(team in scope,
      left_join: pending in ^pending_access, on: pending.team_id == team.id,
      left_join: accepted in ^accepted_access, on: accepted.team_id == team.id,
      left_join: rejected in ^rejected_access, on: rejected.team_id == team.id,
      select: %{
        team: team,
        pending: pending.count,
        accepted: accepted.count,
        rejected: rejected.count,
      }
    )
  end
end
