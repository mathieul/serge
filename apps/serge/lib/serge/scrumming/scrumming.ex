defmodule Serge.Scrumming do
  @moduledoc """
  The boundary for the Scrumming system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Serge.Repo

  alias Serge.Scrumming.{Team, TeamAccess}

  @doc """
  List all teams for owner.
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
  Creates a team for a user, along with a read/write team access.
  """
  def create_team(attrs, owner: owner) when is_map(attrs) and is_map(owner) do
    case do_create_team_and_access(attrs, owner) do
      {:ok, result} ->
        {:ok, result.team}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp do_create_team(attrs, owner) do
    owner
    |> Ecto.build_assoc(:teams)
    |> team_changeset(attrs)
    |> Repo.insert
  end

  defp do_create_team_and_access(attrs, owner) do
    Ecto.Multi.new
    |> Ecto.Multi.run(:team, fn _ -> do_create_team(attrs, owner) end)
    |> Ecto.Multi.run(:access, fn %{team: team} ->
      create_team_access(%{kind: :read_write}, user: owner, team: team)
    end)
    |> Repo.transaction
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
    |> cast(attrs, [:name, :description, :owner_id])
    |> validate_required([:name, :owner_id])
  end

  @doc """
  List all team accesses with teams for owner.
  """
  def list_team_accesses(user: user) when is_map(user) do
    TeamAccess.for_user_id(user.id)
    |> Repo.all()
    |> Repo.preload(:team)
    |> Enum.map(fn access -> %{access | user: user} end)
  end

  @doc """
  Creates a team access for a user and a team.
  """
  def create_team_access(attrs, user: user, team: team)
  when is_map(attrs) and is_map(user) and is_map(team) do
    attrs = Map.put(attrs, :team_id, team.id)
    user
    |> Ecto.build_assoc(:team_accesses)
    |> team_access_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking team changes.
  """
  def change_team_access(%TeamAccess{} = team_access) do
    team_access_changeset(team_access, %{})
  end

  defp team_access_changeset(%TeamAccess{} = team_access, attrs) do
    team_access
    |> cast(attrs, [:user_id, :team_id, :kind])
    |> validate_required([:user_id, :team_id, :kind])
  end
end
