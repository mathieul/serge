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
    from(t in scope, order_by: [asc: :scheduled_on, asc: :rank])
  end

  def previous_work_day(scope \\ __MODULE__) do
    today = DateHelpers.today()
    from(t in scope, where: t.completed_on < ^today, select: max(t.completed_on))
  end

  def starting_from(scope \\ __MODULE__, date) do
    from(t in scope,
      where: t.completed_on >= ^date,
      or_where: is_nil(t.completed_on) and t.scheduled_on >= ^date,
      or_where: is_nil(t.completed_on) and is_nil(t.scheduled_on))
  end

  def last_for_user_and_scheduled_on(scope \\ __MODULE__, user_id, scheduled_on) do
    selection = from(t in scope,
      where: t.user_id == ^user_id,
      order_by: [desc: :rank],
      limit: 1)
    with_same_scheduled_on(selection, scheduled_on)
  end

  def before_task(scope \\ __MODULE__, task) do
    selection = from(t in scope,
      where: t.user_id == ^task.user_id,
      where: t.rank < ^task.rank,
      order_by: [desc: :rank],
      limit: 1
    )
    with_same_scheduled_on(selection, task.scheduled_on)
  end

  def after_task(scope \\ __MODULE__, task) do
    selection = from(t in scope,
      where: t.user_id == ^task.user_id,
      where: t.rank > ^task.rank,
      order_by: [asc: :rank],
      limit: 1
    )
    with_same_scheduled_on(selection, task.scheduled_on)
  end

  defp with_same_scheduled_on(scope \\ __MODULE__, scheduled_on) do
    if is_nil(scheduled_on) do
      from(t in scope, where: is_nil(t.scheduled_on))
    else
      scope |> where(scheduled_on: ^scheduled_on)
    end
  end
end
