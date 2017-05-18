defmodule Serge.Scrumming.StoryTest do
  use Serge.DataCase
  import Serge.Factory

  alias Serge.Scrumming
  # alias Serge.Scrumming.Story

  setup do
    user = insert(:user)
    team = insert(:team, owner: user, name: "My Team")
    %{
      user:  user,
      team:  team,
      access: insert(:team_access, user: user, team: team)
    }
  end

  describe "list_stories/1" do
    test "it returns all stories for a team ordered by sort", %{team: team} do
      insert(:story, team: team, story: "one", sort: 2.0)
      insert(:story, story: "two")
      insert(:story, team: team, story: "three", sort: 1.5)

      assert Enum.map(Scrumming.list_stories(team: team), &(&1.story)) == ["three", "one"]
    end
  end
end
