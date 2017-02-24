defmodule Serge.Schema.Types do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string
    field :tasks, list_of(:task)
  end

  object :task do
    field :id, :id
    field :label, :string
    field :rank, :integer
    field :user, :user
    field :completed, :boolean
    field :scheduled_on, :date
  end

  object :create_task_response do
    field :tid, :string
    field :task, :task
  end

  scalar :time do
    description "ISOz time"
    parse &Timex.parse(&1, "{ISOz}")
    serialize &Timex.format!(&1, "{ISOz}")
  end

  scalar :date do
    description "ISO8601 date"
    parse &Ecto.Date.cast!/1
    serialize &Ecto.Date.to_iso8601/1
  end
end
