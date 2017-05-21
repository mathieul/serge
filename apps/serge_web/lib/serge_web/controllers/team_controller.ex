defmodule Serge.Web.TeamController do
  use Serge.Web, :controller

  alias Serge.Scrumming

  plug Serge.Web.Oauth.AuthorizePlug
  plug :set_authenticated_layout when action in [:index, :new, :edit]
  plug :shows_navigation_top_bar when action in [:index, :new, :edit, :scrum]

  def index(conn, _params) do
    current_user = conn.assigns[:current_user]
    teams = Scrumming.list_teams(owner: current_user)
    team_accesses = Scrumming.list_team_accesses(user: current_user)
    render(conn, "index.html", teams: teams, team_accesses: team_accesses, page_title: "Teams")
  end

  def new(conn, _params) do
    user = conn.assigns[:current_user]
    changeset = Scrumming.change_team(%Scrumming.Team{owner: user})
    render(conn, "new.html", changeset: changeset, owner: user, page_title: "Teams")
  end

  def create(conn, %{"team" => team_params}) do
    case Scrumming.create_team(team_params, owner: conn.assigns[:current_user]) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Team #{inspect team.name} created successfully.")
        |> redirect(to: team_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        user = conn.assigns[:current_user]
        render(conn, "new.html", changeset: changeset, owner: user, page_title: "Teams")
    end
  end

  def edit(conn, %{"id" => id}) do
    user = conn.assigns[:current_user]
    team =
      id
      |> Scrumming.get_team!(owner: user)
      |> Scrumming.preload_team_accesses
    changeset = Scrumming.change_team(team)
    render(conn, "edit.html", team: team, changeset: changeset, owner: user, page_title: "Teams")
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    user = conn.assigns[:current_user]
    team =
      id
      |> Scrumming.get_team!(owner: user)
      |> Scrumming.preload_team_accesses

    case Scrumming.update_team(team, team_params) do
      {:ok, team} ->
        for invitation <- Scrumming.team_pending_invitations(team) do
          team
          |> Serge.Web.TeamInviteEmail.invite(invitation)
          |> Serge.Web.Mailer.deliver_later
          Scrumming.mark_team_access_as_sent(invitation)
        end

        conn
        |> put_flash(:info, "Team updated successfully.")
        |> redirect(to: team_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", team: team, changeset: changeset, owner: user, page_title: "Teams")
    end
  end

  def delete(conn, %{"id" => id}) do
    team = Scrumming.get_team!(id, owner: conn.assigns[:current_user])
    {:ok, _team} = Scrumming.delete_team(team)

    conn
    |> put_flash(:info, "Team deleted successfully.")
    |> redirect(to: team_path(conn, :index))
  end

  def scrum(conn, %{"team_id" => team_id}) do
    team = Scrumming.get_team!(team_id)
    if Scrumming.can_access_team?(team, user: conn.assigns[:current_user]) do
      team = Scrumming.preload_members(team)
      config = elm_app_config(team, conn.assigns.current_user, conn.assigns.access_token)
      render(conn, "scrum.html", elm_module: "Scrum", elm_app_config: config)
    else
      conn
      |> put_flash(:danger, "You are not allowed to access this team.")
      |> redirect(to: team_path(conn, :index))
    end
  end

  defp elm_app_config(_, nil, _), do: %{}
  defp elm_app_config(team, current_user, access_token) do
    %{
      "team" => %{
        "id" => to_string(team.id),
        "name" => team.name,
        "members" => Enum.map(team.members, &user_attributes/1)
      },
      "user" => user_attributes(current_user),
      "auth" => %{
        "access_token" => access_token
      }
    }
  end

  defp user_attributes(user) do
    %{
      "id" => to_string(user.id),
      "name" => user.name,
      "email" => user.email
    }
  end
end
