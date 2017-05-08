defmodule Serge.Web.TeamView do
  use Serge.Web, :view
  alias Serge.Scrumming
  alias Serge.Scrumming.{Team, TeamAccess}

  def link_to_team_access_fields(team_id, owner: owner) do
    changeset = Scrumming.change_team(%Team{team_accesses: [
      %TeamAccess{
        kind: :read_write,
        team_id: team_id
      }
    ]})
    form = Phoenix.HTML.FormData.to_form(changeset, [])
    fields = render_to_string(__MODULE__, "team_access_fields.html",
      form: form,
      owner: owner
    )
    link "Invite team member",
      to: "#",
      data: [template: fields],
      id: "add-team-access",
      class: "btn btn-info btn-sm"
  end
end
