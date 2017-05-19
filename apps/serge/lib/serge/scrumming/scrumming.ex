defmodule Serge.Scrumming do
  @moduledoc """
  The boundary for the Scrumming system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Serge.Repo
  alias Serge.Scrumming.{Team, TeamAccess, Story}
  alias Serge.DateHelpers, as: DH

  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

  @doc """
  List all teams for owner.
  """
  def list_teams(owner: owner) when is_map(owner) do
    Team.for_owner_id(owner.id)
    |> Team.ordered_by_name()
    |> Team.with_team_access_counts()
    |> Repo.all()
    |> Enum.map(fn res ->
      %{res.team | count_pending: res.pending || 0,
                   count_accepted: res.accepted || 0,
                   count_rejected: res.rejected || 0,
                   owner: owner}
    end)
  end

  @doc """
  Gets a single team and return nil if not found.
  """
  def get_team!(id) do
    Repo.get!(Team, id)
  end

  @doc """
  Gets a single team and return nil if not found.
  """
  def get_team(id, owner: owner) when is_map(owner) do
    do_get_team(id, owner, &Repo.get/2)
  end

  @doc """
  Gets a single team and raise Ecto.NoResultsError if not found.
  """
  def get_team!(id, owner: owner) when is_map(owner) do
    do_get_team(id, owner, &Repo.get!/2)
  end

  defp do_get_team(id, owner, getter) do
    case Team
    |> Team.for_owner_id(owner.id)
    |> getter.(id) do
      nil ->
        nil
      team ->
        %{team | owner: owner}
    end
  end

  @doc """
  Preload team_accesses.
  """
  def preload_team_accesses(team) do
    with_accesses = Repo.preload(team, team_accesses: :user)
    %{with_accesses | team_accesses: Enum.map(with_accesses.team_accesses, &set_team_access_status/1)}
  end

  defp set_team_access_status(access) do
    %{access | status: cond do
      access.accepted_at ->
        "member since #{DH.mmddyy(access.accepted_at)}"

      access.rejected_at ->
        "rejected on #{DH.mmddyy(access.rejected_at)}"

      access.user_id ->
        "created on #{DH.mmddyy(access.inserted_at)}"

      true ->
        if is_nil(access.sent_at) do
          "pending"
        else
          "pending (invite sent)"
        end
    end}
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
      create_team_access(%{kind: :read_write, accepted_at: DH.now()}, user: owner, team: team)
    end)
    |> Repo.transaction
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
    |> cast_assoc(:team_accesses, with: &team_access_changeset/2)
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
  Get a team access by its token.
  """
  def get_team_access_by_token(token) do
    TeamAccess
    |> Repo.get_by(token: token)
    |> Repo.preload(team: :owner)
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
    |> cast(attrs, [:user_id, :team_id, :kind, :email, :delete, :accepted_at, :rejected_at])
    |> validate_format(:email, @email_regex)
    |> validate_required([:kind])
    |> validate_email_or_user_id_present
    |> set_delete_action
    |> initialize_if_new
  end

  @doc """
  Returns if a team access can be accepted.
  """
  def team_access_acceptable?(team_access) do
    case Ecto.DateTime.compare(team_access.expires_at, DH.now()) do
      :gt ->
        is_nil(team_access.accepted_at) && is_nil(team_access.rejected_at)

      _ ->
        false
    end
  end

  @doc """
  Allow to accept a team access
  """
  def accept_team_access(team_access, user: user) do
    accept_or_reject_team_access(team_access, :accepted_at, user.id)
  end

  @doc """
  Allow to accept a team access
  """
  def reject_team_access(team_access, user: user) do
    accept_or_reject_team_access(team_access, :rejected_at, user.id)
  end

  defp accept_or_reject_team_access(team_access, time_field, user_id) do
    if team_access_acceptable?(team_access) do
      team_access
      |> team_access_changeset(%{time_field => DH.now(), user_id: user_id})
      |> Repo.update()
      true
    else
      false
    end
  end

  @doc """
  Send an invitation to join the team for each pending team access that hasn't yet been sent.
  """
  def team_pending_invitations(%Team{} = team) do
    TeamAccess.for_team_id(team.id)
    |> TeamAccess.pending()
    |> TeamAccess.not_sent()
    |> Repo.all()
  end

  @doc """
  Mark team access as being just sent.
  """
  def mark_team_access_as_sent(%TeamAccess{} = team_access) do
    case team_access.sent_at do
      nil ->
        team_access
        |> cast(%{sent_at: DH.now()}, [:sent_at])
        |> Repo.update()
        true

      _ ->
        false
    end
  end

  defp validate_email_or_user_id_present(changeset) do
    cond do
      get_field(changeset, :user_id) ->
        changeset

      (get_field(changeset, :email) || "" |> String.trim) != "" ->
        changeset

      true ->
        add_error(changeset, :email, "is required")
    end
  end

  defp set_delete_action(changeset) do
    if get_change(changeset, :delete) do
      %{changeset | action: :delete}
    else
      changeset
    end
  end

  defp initialize_if_new(changeset) do
    case get_field(changeset, :token) do
      nil ->
        changeset
        |> put_change(:token, SecureRandom.hex(32))
        |> put_change(:expires_at, DH.days_from_now(3, as_time: true))

      _ ->
        changeset
    end
  end

  @doc """
  List all stories for a team.
  """
  def list_stories(team: team) when is_map(team) do
    Story.for_team_id(team.id)
    |> Story.ordered_by_sort_and_inserted_at
    |> Repo.all()
    |> Repo.preload(:creator)
    |> Repo.preload(:dev)
    |> Repo.preload(:pm)
    |> Enum.map(fn story -> %{story | team: team} end)
  end

  @doc """
  Creates a story for a creator.
  """
  def create_story(attrs, creator_id: creator_id) do
    attrs = Map.put_new(attrs, :creator_id, creator_id)
    create_story(attrs)
  end

  @doc """
  Creates a story.
  """
  def create_story(attrs \\ %{}) do
    story_changeset(%Story{}, attrs)
    |> Repo.insert()
  end

  defp story_changeset(%Story{} = story, attrs) do
    story
    |> cast(attrs, [:creator_id, :team_id, :dev_id, :pm_id, :sort, :epic, :points, :description])
    |> validate_required([:creator_id, :team_id, :description])
  end
end
