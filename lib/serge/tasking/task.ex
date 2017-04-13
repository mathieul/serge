defmodule Serge.Tasking.Task do
  use Ecto.Schema
  import Ecto.Query
  alias Serge.DateHelpers

  schema "tasks" do
    field :label,           :string
    field :rank,            :integer
    field :scheduled_on,    Ecto.Date
    field :unschedule,      :boolean, virtual: true
    field :completed_on,    Ecto.Date
    field :uncomplete,      :boolean, virtual: true
    field :before_task_id,  :string, virtual: true
    field :after_task_id,   :string, virtual: true

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

  def last_for_user_and_scheduled_on(scope \\ __MODULE__, user_id, scheduled_on) do
    selection = from(t in scope,
      where: t.user_id == ^user_id,
      order_by: [desc: :rank],
      limit: 1)
    if is_nil(scheduled_on) do
      from(t in selection, where: is_nil(t.scheduled_on))
    else
      selection |> where(scheduled_on: ^scheduled_on)
    end
  end

  def before_task(scope \\ __MODULE__, task) do
    from(t in scope,
      where: t.user_id == ^task.user_id,
      where: t.scheduled_on == ^task.scheduled_on,
      where: t.rank < ^task.rank,
      order_by: [desc: :rank],
      limit: 1
    )
  end

  def after_task(scope \\ __MODULE__, task) do
    from(t in scope,
      where: t.user_id == ^task.user_id,
      where: t.scheduled_on == ^task.scheduled_on,
      where: t.rank > ^task.rank,
      order_by: [asc: :rank],
      limit: 1
    )
  end
end
