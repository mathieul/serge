defmodule Serge.Web.TeamInviteEmail do
  use Bamboo.Phoenix, view: Serge.Web.EmailView

  alias Serge.Scrumming.{Team, TeamAccess}

  def invite(%Team{} = team, %TeamAccess{} = team_access) do
    new_email()
    |> to(team_access.email)
    |> from("support@cloudigisafe.com")
    |> subject("Invite to join team #{team.name}")
    |> assign(:team, team)
    |> render(:invite)
  end
end
