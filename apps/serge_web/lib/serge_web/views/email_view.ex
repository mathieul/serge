defmodule Serge.Web.EmailView do
  use Serge.Web, :view
  import Serge.Web.Router.Helpers

  def invitation_url(team_access) do
    team_invitation_url(Serge.Web.Endpoint, :edit, team_access.token)
  end
end
