defmodule Serge.ScrummingTest do
  use Serge.DataCase
  import Serge.Factory

  alias Serge.Scrumming
  alias Serge.Scrumming.Team

  setup do
    %{user: insert(:user)}
  end

  test "list_teams/1 returns all teams ordered by name", %{user: user} do
    zorglub = insert(:team, owner: user, name: "zorglub")
    insert(:team)
    blahblah = insert(:team, owner: user, name: "blahblah")
    assert Scrumming.list_teams(owner: user) == [blahblah, zorglub]
  end

  test "get_team/2 returns the team with given id owned by the user", %{user: user} do
    team = insert(:team, owner: user)
    assert Scrumming.get_team(team.id, owner: user) == team
  end

  test "get_team/2 raises an error if it doesn't exist or belong to another user", %{user: user} do
    assert Scrumming.get_team(42, owner: user) == nil

    team = insert(:team)
    assert Scrumming.get_team(team.id, owner: user) == nil
  end

  test "create_team/1 with valid data creates a team", %{user: user} do
    assert {:ok, %Team{} = team} = Scrumming.create_team(%{name: "My Team"}, owner: user)
    assert team.name == "My Team"
  end

  test "create_team/1 with invalid data returns error changeset", %{user: user} do
    assert {:error, %Ecto.Changeset{}} = Scrumming.create_team(%{nope: "err"}, owner: user)
  end

  test "update_team_by_id/2 with valid data updates the team", %{user: user} do
    team = insert(:team, owner: user, name: "Original")
    assert {:ok, team} = Scrumming.update_team_by_id(%{"id" => team.id, "name" => "Updated"}, owner: user)
    assert %Team{} = team
    assert team.name == "Updated"
  end

  test "update_team_by_id/2 with invalid data returns error changeset", %{user: user} do
    team = insert(:team, owner: user, name: "Original")
    assert {:error, %Ecto.Changeset{}} = Scrumming.update_team_by_id(%{"id" => team.id, "name" => ""}, owner: user)
    assert team == Scrumming.get_team(team.id, owner: user)
  end

  test "delete_team/1 deletes the team", %{user: user} do
    team = insert(:team, owner: user)
    assert {:ok, %Team{}} = Scrumming.delete_team(team.id, owner: user)
    assert Scrumming.get_team(team.id, owner: user) == nil
  end

  test "change_team/1 returns a team changeset", %{user: user} do
    team = insert(:team, owner: user)
    assert %Ecto.Changeset{} = Scrumming.change_team(team)
  end
end
