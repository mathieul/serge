defmodule Serge.Task do
  use Serge.Web, :model
  import EctoOrdered

  schema "tasks" do
    field :label,         :string
    field :position,      :integer, virtual: true
    field :rank,          :integer
    field :completed_on,  Ecto.Date
    field :scheduled_on,  Ecto.Date

    belongs_to :user, Serge.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:label, :completed_on, :scheduled_on, :position, :user_id])
    |> set_order(:position, :rank, :user_id)
    |> assoc_constraint(:user)
    |> validate_required([:label, :scheduled_on, :user_id])
  end

  def all_ordered_for_user_id(user_id) do
    from(t in __MODULE__, where: t.user_id == ^user_id, order_by: t.rank)
  end
end
