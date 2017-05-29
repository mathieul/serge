defmodule Serge.Story.MutationUpdateStoryTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  @document """
      mutation (
        $id: ID!,
        $devId: ID!,
        $pmId: ID!,
        $sort: Float,
        $epic: String,
        $points: Int,
        $description: String
      ) {
        updateStory(
          id: $id,
          devId: $devId,
          pmId: $pmId,
          sort: $sort,
          epic: $epic,
          points: $points,
          description: $description
        ) {
          id
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

    user  = insert(:user, name: "me")
    dev   = insert(:user, name: "ze dev")
    pm    = insert(:user, name: "ze pm")
    story = insert(:story, dev: dev, pm: pm, sort: 12.0, epic: "BIG PROJECT",
      points: 8, description: "original")
    vars = %{"id" => story.id, "description" => story.description}
    %{user: user, dev: dev, pm: pm, story: story, vars: vars}
  end

  describe "with valid attributes" do
    test "it can set the dev", %{user: user, vars: vars, pm: pm} do
      vars = Map.put(vars, "devId", pm.id)
      {:ok, %{data: result}} = run(@document, user.id, vars)

      assert get_in(result, ["updateStory", "dev", "id"]) == to_string(pm.id)
      assert get_in(result, ["updateStory", "dev", "name"]) == "ze pm"
    end
  end

  describe "with invalid attributes" do
    test "it returns an error if sort type is wrong", %{user: user, vars: vars} do
      vars = Map.put(vars, "sort", "not a float")

      {:ok, %{errors: errors}} = run(@document, user.id, vars)
      assert Enum.all?(errors, &(Regex.match?(~r/^Argument "sort"/, &1.message)))
    end
  end
end
