defmodule Serge.Task do
  use Serge.Web, :model
  import EctoOrdered
  alias Serge.DateHelpers

  schema "tasks" do
    field :label,         :string
    field :position,      :integer, virtual: true
    field :rank,          :integer
    field :completed,     :boolean, virtual: true
    field :completed_on,  Ecto.Date
    field :scheduled_on,  Ecto.Date

    belongs_to :user, Serge.User

    timestamps()
  end

  def changeset(task, params \\ %{}) do
    task
    |> cast(params, [:label, :completed, :scheduled_on, :position, :user_id])
    |> set_order(:position, :rank, :user_id)
    |> update_completed_on
    |> assoc_constraint(:user)
    |> validate_required([:label, :scheduled_on, :user_id])
  end

  defp update_completed_on(changeset) do
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

  def ordered_for_user_id(scope \\ __MODULE__, user_id) do
    from(t in scope, where: t.user_id == ^user_id, order_by: t.rank)
  end

  def guess_yesterdays_work_day(scope \\ __MODULE__) do
    today = DateHelpers.today()
    from(t in scope, where: t.completed_on < ^today, select: max(t.completed_on))
  end

  def excluding_completed(scope \\ __MODULE__) do
    from(t in scope, where: is_nil(t.completed_on))
  end

  def including_completed_from(scope \\ __MODULE__, date) do
    from(t in scope, where: t.completed_on >= ^date or is_nil(t.completed_on))
  end
end
