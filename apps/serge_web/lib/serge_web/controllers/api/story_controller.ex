defmodule Serge.Web.Api.StoryController do
  use Serge.Web, :controller
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
    with {:ok, %Story{} = story} <- Scrumming.create_story(params, team: team, creator: creator) do
      conn
      |> put_status(:created)
      # |> put_resp_header("location", api_histoire_path(conn, :show, histoire))
      |> render("show.json", story: story)
    end
  end

  # def show(conn, %{"id" => id}) do
  #   histoire = Web.Scrumming.get_histoire!(id)
  #   render(conn, "show.json", histoire: histoire)
  # end
  #
  # def update(conn, %{"id" => id, "histoire" => histoire_params}) do
  #   histoire = Web.Scrumming.get_histoire!(id)
  #
  #   with {:ok, %Histoire{} = histoire} <- Web.Scrumming.update_histoire(histoire, histoire_params) do
  #     render(conn, "show.json", histoire: histoire)
  #   end
  # end
  #
  # def delete(conn, %{"id" => id}) do
  #   histoire = Web.Scrumming.get_histoire!(id)
  #   with {:ok, %Histoire{}} <- Web.Scrumming.delete_histoire(histoire) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
