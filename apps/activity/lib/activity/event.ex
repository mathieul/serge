defmodule Activity.Event do
  use Ecto.Schema
  use Timex.Ecto.Timestamps
  import Ecto.Query, only: [from: 2]

  schema "events" do
    field :user_name, :string
    field :avatar_url, :string
    field :message, :string

    timestamps()
  end

  def recent(scope \\ __MODULE__) do
    from(e in scope, order_by: [desc: :inserted_at])
  end
end
