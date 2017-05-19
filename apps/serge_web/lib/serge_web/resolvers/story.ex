defmodule Serge.Web.Resolvers.Story do
  import Serge.Web.Resolvers.Helpers, only: [format_changeset_errors: 1]

  alias Serge.Scrumming

  def all(_parent, %{team_id: team_id}, %{context: ctx}) do
    team = Scrumming.get_team!(team_id)
    stories = Scrumming.list_stories(team: team)
    {:ok, stories}
  end

  def create(_parent, attributes = %{team_id: team_id}, %{context: ctx}) do
    team = Scrumming.get_team!(team_id)
    case Scrumming.create_story(attributes, creator_id: ctx.current_user.id) do
      {:ok, story} ->
        {:ok, story}

      {:error, changeset} ->
        {:error, format_changeset_errors(changeset)}
    end
  end
end
