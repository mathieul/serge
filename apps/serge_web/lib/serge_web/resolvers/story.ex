defmodule Serge.Web.Resolvers.Story do
  import Serge.Web.Resolvers.Helpers, only: [format_changeset_errors: 1]

  alias Serge.Scrumming

  def all(_parent, %{team_id: team_id}, _) do
    team = Scrumming.get_team!(team_id)
    stories = Scrumming.list_stories(team: team)
    {:ok, stories}
  end

  def create(_parent, attributes = %{team_id: team_id}, %{context: ctx}) do
    team = Scrumming.get_team!(team_id)
    case Scrumming.create_story(attributes, team: team, creator: ctx.current_user) do
      {:ok, story} ->
        {:ok, story}

      {:error, changeset} ->
        {:error, format_changeset_errors(changeset)}
    end
  end

  def update(_parent, attributes, %{context: ctx}) do
    case Scrumming.update_story_by_id(attributes, user: ctx.current_user) do
      { :error, changeset } ->
        { :error, format_changeset_errors(changeset) }
      ok ->
        ok
    end
  end
end
