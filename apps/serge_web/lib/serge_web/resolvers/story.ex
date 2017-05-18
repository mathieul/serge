defmodule Serge.Web.Resolvers.Story do
  # alias Serge.Scrumming

  def all(_parent, %{team_id: team_id}, %{context: ctx}) do
    IO.puts "TODO: all(#{inspect team_id}, #{inspect ctx})"
    # team = Scrumming.
    # stories = Scrumming.list_stories(team: )
    # { :ok, tasks }
    {:ok, []}
  end
end
