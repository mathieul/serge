defmodule Serge.Web.Resolvers.Team do
  alias Serge.Scrumming

  def all(_parent, args, %{context: ctx}) do
    teams = Scrumming.list_teams(owner_id: ctx.current_user.id)
    {:ok, teams}
  end
end
