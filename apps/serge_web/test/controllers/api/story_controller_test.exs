defmodule Serge.Web.Api.StoryControllerTest do
  use Serge.Web.ConnCase
  use Plug.Test
  import Serge.Factory

  setup do
    user = insert(:user)
    team = insert(:team)
    insert(:team_access, user: user, team: team)
    %{
      conn: put_req_header(build_conn(), "accept", "application/json"),
      user: user,
      team: team
    }
  end

  describe "GET :index" do
    test "returns an empty list when the team has no stories", %{conn: conn, user: user, team: team} do
      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> get(api_story_path(conn, :index, team.id))

      assert json_response(conn, 200)["data"] == %{"stories" => []}
    end

    test "returns team stories when present", %{conn: conn, user: user, team: team} do
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

  describe "POST :create" do
    test "creates a story with valid attributes", %{conn: conn, user: user, team: team} do
      dev = insert(:user, name: "John Zorn")
      pm  = insert(:user, name: "Ann Onimus")
      attributes = %{
        dev_id: dev.id,
        pm_id: pm.id,
        sort: 12,
        epic: "EPIC",
        points: 8,
        description: "as a user..."
      }
      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> post(api_story_path(conn, :create, team.id), attributes)

      story = json_response(conn, 201)["data"]["story"]
      assert story["creator_id"] == user.id
      assert story["dev_id"] == dev.id
      assert story["pm_id"] == pm.id
      assert story["sort"] == 12
      assert story["epic"] == "EPIC"
      assert story["points"] == 8
      assert story["description"] == "as a user..."
    end

    test "returns an error with invalid attributes", %{conn: conn, user: user, team: team} do
      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> post(api_story_path(conn, :create, team.id), %{"epic" => 42})

      errors = json_response(conn, 422)["errors"]
      assert errors["epic"] == ["is invalid"]
    end
  end

  describe "PUT :update" do
    test "updates a story with valid attributes", %{conn: conn, user: user, team: team} do
      story = insert(:story, team: team, description: "Ze Story")
      dev = insert(:user, name: "John Zorn")

      attributes = %{
        dev_id: dev.id,
        epic: "FOREVER",
        points: 5,
        description: "blah blah blah"
      }
      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> patch(api_story_path(conn, :update, team.id, story.id), %{"story" => attributes})

        result = json_response(conn, 200)["data"]["story"]
        assert result["dev_id"] == dev.id
        assert result["epic"] == "FOREVER"
        assert result["points"] == 5
        assert result["description"] == "blah blah blah"

      updated = Serge.Scrumming.get_story!(story.id)
      assert updated.dev_id == dev.id
      assert updated.epic == "FOREVER"
      assert updated.points == 5
      assert updated.description == "blah blah blah"
    end

    test "returns an error with invalid attributes", %{conn: conn, user: user, team: team} do
      story = insert(:story, team: team, description: "Ze Story")

      conn =
        conn
        |> init_test_session(current_user_id: user.id)
        |> patch(api_story_path(conn, :update, team.id, story.id), %{"story" => %{"points" => "invalid"}})

      errors = json_response(conn, 422)["errors"]
      assert errors["points"] == ["is invalid"]
    end
  end
end
