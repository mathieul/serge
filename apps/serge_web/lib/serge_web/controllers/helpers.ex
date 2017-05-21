defmodule Serge.Web.Controllers.Helpers do
  import Phoenix.Controller, only: [put_layout: 2]
  import Plug.Conn

  def set_authenticated_layout(conn, _options) do
    put_layout(conn, "authenticated.html")
  end

  def shows_navigation_top_bar(conn, _options) do
    current_user = conn.assigns[:current_user]
    team_accesses = Serge.Scrumming.list_team_accesses(user: current_user)
    team_values =
      team_accesses
      |> Enum.map(fn access -> {access.team.id, access.team.name} end)
      |> Enum.dedup

    conn
    |> assign(:team_accesses, team_accesses)
    |> assign(:team_values, team_values)
  end
end
