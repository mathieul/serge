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
    |> cast(params, [:label, :completed_at, :rank])
    |> validate_required([:label, :rank])
  end
end
