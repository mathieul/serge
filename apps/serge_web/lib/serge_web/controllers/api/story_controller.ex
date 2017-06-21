defmodule Serge.Web.Api.StoryController do
  use Serge.Web, :controller
  import Ecto.Changeset, only: [add_error: 3]
  alias Serge.Scrumming
  alias Serge.Scrumming.Story

  action_fallback Serge.Web.FallbackController

  def index(conn, %{"team_id" => team_id}) do
    team = Scrumming.get_team!(team_id)
    if Scrumming.can_access_team?(team, user: conn.assigns.current_user, can_write: false) do
      stories = Scrumming.list_stories(team: team)
      render(conn, "index.json", stories: stories)
    else
      {:error, :not_authorized}
    end
  end

  def create(conn, params = %{"team_id" => team_id}) do
    team = Scrumming.get_team!(team_id)
    creator = conn.assigns.current_user
    if Scrumming.can_access_team?(team, user: creator, can_write: true) do
      with {:ok, %Story{} = story} <- Scrumming.create_story(params, team: team, creator: creator) do
        conn
        |> put_status(:created)
        |> render("show.json", story: story)
      end
    else
      changeset = Scrumming.change_story(%Story{})
      {:error, add_error(changeset, :creator, "user #{inspect creator.name} can't write in team #{team.name}")}
    end
  end

  def update(conn, %{"team_id" => team_id, "id" => id, "story" => story_params}) do
    team = Scrumming.get_team!(team_id)
    user = conn.assigns.current_user
    if Scrumming.can_access_team?(team, user: user, can_write: true) do
      story = Scrumming.get_story!(id)
      with {:ok, %Story{} = story} <- Scrumming.update_story(story, story_params) do
        render(conn, "show.json", story: story)
      end
    else
    end
  end

  # def delete(conn, %{"id" => id}) do
  #   story = Scrumming.get_story!(id)
  #   with {:ok, %Story{}} <- Scrumming.delete_story(story) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
