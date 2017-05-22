defmodule Serge.Task.QueryTasksTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)

    user = insert(:user)
    team = insert(:team, owner: user, name: "My Team")
    %{
      user:  user,
      team:  team,
      access: insert(:team_access, user: user, team: team)
    }
  end

  test "it returns an empty array when there are no tasks", ctx do
    doc = "query { stories(teamId: #{ctx[:team].id}) { description } }"
    {:ok, %{data: result}} = run(doc, ctx[:user].id)
    assert result["stories"] == []
  end

  test "it returns all tasks for the current user when present", ctx do
    insert(:story, team: ctx[:team], description: "One")
    insert(:story, description: "Two")
    insert(:story, team: ctx[:team], description: "Three")
    insert(:story, team: ctx[:team], description: "Four")

    doc = "query { stories(teamId: #{ctx[:team].id}) { description } }"
    {:ok, %{data: result}} = run(doc, ctx[:user].id)
    assert story_descriptions(result) == ["One", "Three", "Four"]
  end

  defp story_descriptions(result) do
    Enum.map(result["stories"], fn %{"description" => description} -> description end)
  end
end
