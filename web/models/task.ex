defmodule Serge.Task do
  use Serge.Web, :model
  import EctoOrdered

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
           put_change(changeset, :completed_on, now())
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

  defp now do
    Timex.local
      |> Timex.format!("%Y-%m-%d", :strftime)
      |> Ecto.Date.cast!
  end

  def all_ordered_for_user_id(user_id) do
    from(t in __MODULE__, where: t.user_id == ^user_id, order_by: t.rank)
  end

  def set_virtual_fields(task) do
    task
    |> Map.put(:completed, !!task.completed_on)
  end
end
