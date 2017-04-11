defmodule Serge.Web.Schema.TaskTypes do
  use Absinthe.Schema.Notation

  object :task do
    field :id, :id
    field :label, :string
    field :rank, :integer
    field :user, :user
    field :completed_on, :date
    field :scheduled_on, :date
  end

  object :create_task_response do
    field :tid, :string
    field :task, :task
  end
end
