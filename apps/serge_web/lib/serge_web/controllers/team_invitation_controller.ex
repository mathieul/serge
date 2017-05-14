defmodule Serge.Web.TeamInvitationController do
  use Serge.Web, :controller
  alias Serge.Scrumming

  plug Serge.Web.Oauth.AuthorizePlug
  plug :fetch_team_access
  plug :set_authenticated_layout
  plug :shows_navigation_top_bar when action in [:edit]

  def edit(conn, _params) do
    render(conn, "edit.html", page_title: "Join Team")
  end

  def accept(conn, _params) do
    if Scrumming.accept_team_access(conn.assigns.team_access, user: conn.assigns.current_user) do
      put_flash(conn, :info, "You've accepted the invitation.")
    else
      put_flash(conn, :error, "Accepting the invitation failed - please refer to the author of the invitation.")
    end
    |> redirect(to: team_path(conn, :index))
  end

  def reject(conn, _params) do
    if Scrumming.reject_team_access(conn.assigns.team_access, user: conn.assigns.current_user) do
      put_flash(conn, :info, "You've rejected the invitation.")
    else
      put_flash(conn, :error, "Rejecting the invitation failed - please refer to the author of the invitation.")
    end
    |> redirect(to: team_path(conn, :index))
  end

  defp fetch_team_access(conn, _options) do
    token = conn.params["id"]
    case Scrumming.get_team_access_by_token(token) do
      nil ->
        conn
        |> put_flash(:danger, "Can't find this team invitation - please request new invitation.")
        |> redirect(to: team_path(conn, :index))
        |> halt()

      team_access ->
        conn
        |> assign(:team_access, team_access)
        |> assign(:team_access_acceptable, Scrumming.team_access_acceptable?(team_access))
    end
  end
end
