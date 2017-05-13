defmodule Serge.Web.TeamInviteEmail do
  import Bamboo.Email

  alias Serge.Scrumming.{Team, TeamAccess}

  def invite(%Team{} = team, %TeamAccess{} = team_access) do
    new_email(
      to: team_access.email,
      from: "support@cloudigisafe.com",
      subject: "Invite to join team #{team.name}",
      text_body: text(team, team_access)
    )
  end

  defp text(team, _team_access) do
    """
    You've been invited to join team #{team.name}!

    You can accept or reject the invitation by going to this address: TODO.

    Cheers,

    Serge
    """
  end
end
