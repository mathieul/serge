defmodule Serge.Tasking.Task do
  use Ecto.Schema

  import Ecto.Query

  alias Serge.DateHelpers

  schema "tasks" do
    field :label,         :string
    field :rank,          :integer, default: 0
    field :scheduled_on,  Ecto.Date
    field :unschedule,    :boolean, virtual: true
    field :completed_on,  Ecto.Date
    field :uncomplete,    :boolean, virtual: true

    belongs_to :user, Serge.Authentication.User

    timestamps()
  end

  ###
  # Queries
  ###

  def for_user_id(scope \\ __MODULE__, user_id) do
    from(t in scope, where: t.user_id == ^user_id)
  end

  def ordered_by_schedule_and_rank(scope \\ __MODULE__) do
    from(t in scope, order_by: [t.scheduled_on, t.rank])
  end

  def previous_work_day(scope \\ __MODULE__) do
    today = DateHelpers.today()
    from(t in scope, where: t.completed_on < ^today, select: max(t.completed_on))
  end

  def starting_from(scope \\ __MODULE__, date) do
    from(t in scope,
      where: t.completed_on >= ^date,
      or_where: is_nil(t.completed_on) and t.scheduled_on >= ^date)
  end
end
