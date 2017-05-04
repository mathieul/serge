defmodule Serge.Web.TeamController do
  use Serge.Web, :controller

  alias Serge.Scrumming

  plug :set_authenticated_layout

  def index(conn, _params) do
    teams = Scrumming.list_teams(owner: conn.assigns[:current_user])
    render(conn, "index.html", teams: teams, page_title: "Teams")
  end

  def new(conn, _params) do
    changeset = Scrumming.change_team(%Scrumming.Team{owner_id: conn.assigns[:current_user].id})
    render(conn, "new.html", changeset: changeset, page_title: "Teams")
  end

  def create(conn, %{"team" => team_params}) do
    case Scrumming.create_team(team_params, owner: conn.assigns[:current_user]) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Team #{inspect team.name} created successfully.")
        |> redirect(to: team_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    team = Scrumming.get_team!(id, owner: conn.assigns[:current_user])
    changeset = Scrumming.change_team(team)
    render(conn, "edit.html", team: team, changeset: changeset, page_title: "Teams")
  end

  def update(conn, %{"id" => id, "team" => team_params}) do
    team = Scrumming.get_team!(id, owner: conn.assigns[:current_user])

    case Scrumming.update_team(team, team_params) do
      {:ok, team} ->
        conn
        |> put_flash(:info, "Team updated successfully.")
        |> redirect(to: team_path(conn, :index))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", team: team, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    team = Scrumming.get_team!(id, owner: conn.assigns[:current_user])
    {:ok, _team} = Scrumming.delete_team(team)

    conn
    |> put_flash(:info, "Team deleted successfully.")
    |> redirect(to: team_path(conn, :index))
  end

  defp set_authenticated_layout(conn, _options) do
    put_layout(conn, "authenticated.html")
  end
end
