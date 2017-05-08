defmodule Serge.Scrumming.TeamAccess do
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query

  schema "team_accesses" do
    field :kind,        AccessKindEnum
    field :email,       :string
    field :token,       :string
    field :expires_at,  Ecto.DateTime
    field :accepted_at, Ecto.DateTime
    field :rejected_at, Ecto.DateTime

    field :delete,      :boolean,     virtual: true

    belongs_to :user,   Serge.Authentication.User
    belongs_to :team,   Serge.Scrumming.Team

    timestamps()
  end

  ###
  # Queries
  ###

  def for_user_id(scope \\ __MODULE__, user_id) do
    from(t in scope, where: t.user_id == ^user_id)
  end
end
