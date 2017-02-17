defmodule Serge.Task do
  use Serge.Web, :model
  import EctoOrdered

  schema "tasks" do
    field :label,         :string
    field :completed_at,  Ecto.DateTime
    field :position,      :integer, virtual: true
    field :rank,          :integer

    belongs_to :user, Serge.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:label, :completed_at, :position, :user_id])
    |> set_order(:position, :rank, :user_id)
    |> assoc_constraint(:user)
    |> validate_required([:label, :user_id])
  end

  def all_ordered_for_user_id(user_id) do
    from(t in __MODULE__, where: t.user_id == ^user_id, order_by: t.rank)
  end

  def all_ordered do
    from(t in __MODULE__, order_by: t.rank)
  end
end
