defmodule Serge.Scrumming.Team do
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query

  schema "teams" do
    field :name, :string
    belongs_to :owner, Serge.Authentication.User

    timestamps()
  end

  ###
  # Queries
  ###

  def for_owner_id(scope \\ __MODULE__, owner_id) do
    from(t in scope, where: t.owner_id == ^owner_id)
  end

  def ordered_by_name(scope \\ __MODULE__) do
    from(t in scope, order_by: [asc: :name])
  end
end
