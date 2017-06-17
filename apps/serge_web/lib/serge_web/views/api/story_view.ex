defmodule Serge.Web.Api.StoryView do
  use Serge.Web, :view
  alias Serge.Web.Api.StoryView

  def render("index.json", %{stories: stories}) do
    %{
      data: %{
        stories: render_many(stories, StoryView, "story.json")
      }
    }
  end

  def render("story.json", %{story: story}) do
    %{
      id: story.id,
      creator_id: story.creator_id,
      dev_id: story.dev_id,
      pm_id: story.pm_id,
      sort: story.sort,
      epic: story.epic,
      description: story.description
    }
  end
end
