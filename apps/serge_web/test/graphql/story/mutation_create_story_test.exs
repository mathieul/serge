defmodule Serge.Story.MutationCreateStoryTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  @document """
      mutation (
        $teamId: ID!,
        $devId: ID!,
        $pmId: ID!,
        $sort: Float,
        $epic: String,
        $points: Int,
        $description: String
      ) {
        createStory(
          teamId: $teamId,
          devId: $devId,
          pmId: $pmId,
          sort: $sort,
          epic: $epic,
          points: $points,
          description: $description
        ) {
          id
          team {
            id
            name
          }
          creator {
            id
            name
          }
          dev {
            id
            name
          }
          pm {
            id
            name
          }
          sort
          epic
          points
          description
        }
      }
    """

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)

    user = insert(:user, name: "me")
    dev = insert(:user, name: "ze dev")
    pm = insert(:user, name: "ze pm")
    team = insert(:team, owner: user, name: "My Team")
    %{
      user:   user,
      dev:    dev,
      pm:     pm,
      team:   team,
      access: insert(:team_access, user: user, team: team),
      variables: %{
        "teamId" => team.id,
        "devId" => dev.id,
        "pmId" => pm.id,
        "sort" => 1.42,
        "epic" => "GIANT",
        "points" => 5,
        "description" => "as a thing I want a stuff so I can have the stuff"
      }
    }
  end

  describe "with valid attributes" do
    @tag :skip
    test "it creates a story", ctx do
      {:ok, %{data: result}} = run(@document, ctx.user.id, ctx.variables)

      assert get_in(result, ["createStory", "creator", "id"]) == to_string(ctx.user.id)
      assert get_in(result, ["createStory", "creator", "name"]) == "me"

      assert get_in(result, ["createStory", "team", "id"]) == to_string(ctx.team.id)
      assert get_in(result, ["createStory", "team", "name"]) == "My Team"

      assert get_in(result, ["createStory", "dev", "id"]) == to_string(ctx.dev.id)
      assert get_in(result, ["createStory", "dev", "name"]) == "ze dev"

      assert get_in(result, ["createStory", "pm", "id"]) == to_string(ctx.pm.id)
      assert get_in(result, ["createStory", "pm", "name"]) == "ze pm"

      assert get_in(result, ["createStory", "sort"]) == 1.42
      assert get_in(result, ["createStory", "epic"]) == "GIANT"
      assert get_in(result, ["createStory", "points"]) == 5
      assert get_in(result, ["createStory", "description"]) == "as a thing I want a stuff so I can have the stuff"

      # created = Serge.Repo.get(Serge.Scrumming.Story, result["createStory"]["id"])
      # require IEx; IEx.pry
    end
  end

  describe "with invalid attributes" do
    test "it returns an error if teamId is missing", ctx do
      variables = Map.drop(ctx.variables, ["teamId"])

      {:ok, %{errors: errors}} = run(@document, ctx.user.id, variables)
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "teamId"/, &1.message)))
    end
  end
end
