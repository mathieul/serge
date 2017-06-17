defmodule Serge.Web.Api.StoryControllerTest do
  use Serge.Web.ConnCase
  use Plug.Test
  import Serge.Factory

  setup do
    %{
      conn: put_req_header(build_conn(), "accept", "application/json"),
      user: insert(:user),
      team: insert(:team)
    }
  end

  describe "GET :index" do
    test "returns an empty list when the team has no stories", %{conn: conn, user: user, team: team} do
      insert(:team_access, user: user, team: team)
      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> get(api_story_path(conn, :index, team.id))

      assert json_response(conn, 200)["data"] == %{"stories" => []}
    end

    test "returns team stories when present", %{conn: conn, user: user, team: team} do
      insert(:team_access, user: user, team: team)
      insert(:story, team: team, description: "Story One")
      insert(:story, team: team, description: "Story Two")

      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> get(api_story_path(conn, :index, team.id))

      stories = json_response(conn, 200)["data"]["stories"]
      assert Enum.map(stories, &Access.get(&1, "description")) == ["Story One", "Story Two"]
    end
  end
end
