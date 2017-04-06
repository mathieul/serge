defmodule Serge.Tasking.Task do
  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset
  import EctoOrdered

  alias Serge.DateHelpers

  schema "tasks" do
    field :label,         :string
    field :position,      :integer, virtual: true
    field :rank,          :integer
    field :completed,     :boolean, virtual: true
    field :completed_on,  Ecto.Date
    field :scheduled_on,  Ecto.Date

    belongs_to :user, Serge.Authentication.User

    timestamps()
  end

  def ordered(changeset) do
    set_order(changeset, :position, :rank, :user_id)
  end

  def update_completed_on(changeset) do
    completed_on = get_field(changeset, :completed_on)
    case get_field(changeset, :completed) do
      true ->
        if completed_on == nil do
           put_change(changeset, :completed_on, DateHelpers.today())
         else
           changeset
        end

      false ->
        if completed_on do
          put_change(changeset, :completed_on, nil)
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  def infer_completed(task) do
    task
    |> Map.put(:completed, !!task.completed_on)
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
