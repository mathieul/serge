defmodule Serge.Team.QueryTeamsTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    [user: insert(:user)]
  end

  test "it returns an empty array when there are no teams", ctx do
    doc = "query { teams { name } }"
    {:ok, %{data: result}} = run(doc, ctx[:user].id)
    assert result["teams"] == []
  end

  test "it returns all teams for the current user when present", ctx do
    insert(:team, owner: ctx[:user], name: "Work")
    insert(:team, name: "Other")
    insert(:team, owner: ctx[:user], name: "Perso")

    doc = "query { teams { name } }"
    {:ok, %{data: result}} = run(doc, ctx[:user].id)
    assert team_names(result) == ["Perso", "Work"]
  end

  defp team_names(result) do
    Enum.map(result["teams"], fn %{"name" => name} -> name end)
  end
end
