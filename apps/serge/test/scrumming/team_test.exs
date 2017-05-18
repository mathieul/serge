defmodule Serge.Scrumming.TeamTest do
  use Serge.DataCase
  import Serge.Factory

  alias Serge.Scrumming
  alias Serge.Scrumming.Team

  setup do
    %{user: insert(:user)}
  end

  describe "list_teams/1" do
    test "it returns all teams ordered by name", %{user: user} do
      insert(:team, owner: user, name: "zorglub")
      insert(:team)
      insert(:team, owner: user, name: "blahblah")
      assert Enum.map(Scrumming.list_teams(owner: user), &(&1.name)) == ["blahblah", "zorglub"]
    end
  end

  describe "get_team/2" do
    test "it returns the team with given id owned by the user", %{user: user} do
      team = insert(:team, owner: user)
      assert Scrumming.get_team(team.id, owner: user) == team
    end

    test "it raises an error if it doesn't exist or belong to another user", %{user: user} do
      assert Scrumming.get_team(42, owner: user) == nil

      team = insert(:team)
      assert Scrumming.get_team(team.id, owner: user) == nil
    end
  end

  describe "create_team/1" do
    test "with valid data it creates a team", %{user: user} do
      assert {:ok, %Team{} = team} = Scrumming.create_team(%{name: "My Team"}, owner: user)
      assert team.name == "My Team"
    end

    test "with valid data it creates a read/write team access", %{user: user} do
      {:ok, team} = Scrumming.create_team(%{name: "My Team"}, owner: user)

      accesses = Scrumming.list_team_accesses(user: user)
      assert length(accesses) == 1
      access = List.first(accesses)
      assert access.user == user
      assert access.team == team
      assert access.kind == :read_write
    end

    test "with invalid data it returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Scrumming.create_team(%{nope: "err"}, owner: user)
    end
  end

  describe "update_team/2" do
    test "with valid data it updates the team", %{user: user} do
      team = insert(:team, owner: user, name: "Original")
      assert {:ok, team} = Scrumming.update_team(team, %{"id" => team.id, "name" => "Updated"})
      assert %Team{} = team
      assert team.name == "Updated"
    end

    test "with invalid data it returns error changeset", %{user: user} do
      team = insert(:team, owner: user, name: "Original")
      {:error, %Ecto.Changeset{}} = Scrumming.update_team(team, %{"id" => team.id, "name" => ""})
      assert team == Scrumming.get_team(team.id, owner: user)
    end
  end

  describe "delete_team/1" do
    test "it deletes the team", %{user: user} do
      team = insert(:team, owner: user)
      assert {:ok, %Team{}} = Scrumming.delete_team(team.id, owner: user)
      assert Scrumming.get_team(team.id, owner: user) == nil
    end
  end

  describe "change_team/1" do
    test "it returns a team changeset", %{user: user} do
      team = insert(:team, owner: user)
      assert %Ecto.Changeset{} = Scrumming.change_team(team)
    end
  end
end
