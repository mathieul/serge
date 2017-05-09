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
    field :status,      :string,      virtual: true

    belongs_to :user,   Serge.Authentication.User
    belongs_to :team,   Serge.Scrumming.Team

    timestamps()
  end

  ###
  # Queries
  ###

  def for_user_id(scope \\ __MODULE__, user_id) do
    from(ta in scope, where: ta.user_id == ^user_id)
  end

  def count(scope \\ __MODULE__) do
    from(ta in scope, group_by: ta.team_id, select: %{team_id: ta.team_id, count: count(ta.id)})
  end

  def accepted(scope \\ __MODULE__) do
    from(ta in scope, where: not is_nil(ta.accepted_at))
  end

  def rejected(scope \\ __MODULE__) do
    from(ta in scope, where: not is_nil(ta.rejected_at))
  end

  def pending(scope \\ __MODULE__) do
    from(ta in scope, where: is_nil(ta.accepted_at) and is_nil(ta.rejected_at))
  end
end
