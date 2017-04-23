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
end
