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

  # test "update_team/2 with valid data updates the team" do
  #   team = fixture(:team)
  #   assert {:ok, team} = Scrumming.update_team(team, @update_attrs)
  #   assert %Team{} = team
  #   assert team.name == "some updated name"
  # end
  #
  # test "update_team/2 with invalid data returns error changeset" do
  #   team = fixture(:team)
  #   assert {:error, %Ecto.Changeset{}} = Scrumming.update_team(team, @invalid_attrs)
  #   assert team == Scrumming.get_team!(team.id)
  # end
  #
  # test "delete_team/1 deletes the team" do
  #   team = fixture(:team)
  #   assert {:ok, %Team{}} = Scrumming.delete_team(team)
  #   assert_raise Ecto.NoResultsError, fn -> Scrumming.get_team!(team.id) end
  # end
  #
  # test "change_team/1 returns a team changeset" do
  #   team = fixture(:team)
  #   assert %Ecto.Changeset{} = Scrumming.change_team(team)
  # end
end
