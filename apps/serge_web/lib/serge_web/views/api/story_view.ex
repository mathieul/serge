defmodule Serge.Web.Api.StoryView do
  use Serge.Web, :view
  alias Serge.Web.Api.StoryView

  def render("index.json", %{stories: stories}) do
    %{data: render_many(stories, StoryView, "story.json")}
  end

  def render("show.json", %{story: story}) do
    %{data: render_one(story, StoryView, "story.json")}
  end

  def render("story.json", %{story: story}) do
    %{
      id: story.id,
      sort: story.sort,
      epic: story.epic,
      description: story.description
    }
  end
end
