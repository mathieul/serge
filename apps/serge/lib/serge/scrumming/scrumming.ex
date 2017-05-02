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
  def list_teams(owner_id: owner_id) do
    Team.for_owner_id(owner_id)
    |> Team.ordered_by_name()
    |> Repo.all()
    |> Repo.preload(:owner)
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
