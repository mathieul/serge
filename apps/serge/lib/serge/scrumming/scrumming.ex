defmodule Serge.Scrumming do
  @moduledoc """
  The boundary for the Scrumming system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Serge.Repo

  alias Serge.Scrumming.Team

  @doc """
  Guess what the previous day of work was.
  """
  def list_teams(owner: owner) when is_map(owner) do
    Team.for_owner_id(owner.id)
    |> Team.ordered_by_name()
    |> Repo.all()
    |> Enum.map(fn team -> %{team | owner: owner} end)
  end

  @doc """
  Gets a single task and raise Ecto.NoResultsError if not found.
  """
  def get_team(id, owner: owner) when is_map(owner) do
    case Team
    |> Team.for_owner_id(owner.id)
    |> Repo.get(id) do
      nil ->
        nil
      team ->
        %{team | owner: owner}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.
  """
  def change_team(%Team{} = team) do
    team_changeset(team, %{})
  end

  defp team_changeset(%Team{} = team, attrs) do
    team
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name, :owner_id])
  end
end
