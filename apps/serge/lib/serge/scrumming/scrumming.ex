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
  Gets a single team and raise Ecto.NoResultsError if not found.
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
  Creates a team for a user.
  """
  def create_team(attrs, owner: owner) when is_map(attrs) and is_map(owner) do
    Ecto.build_assoc(owner, :teams)
    |> team_changeset(attrs)
    |> Repo.insert
  end

  @doc """
  Updates a team from a team id.
  """
  def update_team_by_id(%{"id" => id} = attrs, owner: owner) when is_map(owner) do
    case get_team(id, owner: owner) do
      nil ->
        changeset = change_team(%Team{})
        {:error, add_error(changeset, :team, "doesn't exist")}
      team ->
        update_team(team, attrs)
    end
  end

  @doc """
  Updates a team.
  """
  def update_team(%Team{} = team, attrs) when is_map(attrs) do
    team
    |> team_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a team.
  """
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  @doc """
  Deletes a team from its id.
  """
  def delete_team(id, owner: owner) when is_binary(id) or is_integer(id)  do
    case get_team(id, owner: owner) do
      nil ->
        {:error, "Team doesn't exist"}
      team ->
        delete_team(team)
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
