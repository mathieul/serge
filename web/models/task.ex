defmodule Serge.Task do
  use Serge.Web, :model

  schema "tasks" do
    field :label,         :string
    field :completed_at,  Ecto.DateTime
    field :rank,          :integer

    belongs_to :user, Serge.User

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:label, :completed_at, :rank, :user_id])
    |> assoc_constraint(:user)
    |> validate_required([:label, :rank, :user_id])
  end
end
