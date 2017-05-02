defmodule Serge.Web.Schema do
  use Absinthe.Schema

  alias Serge.Web.Resolvers

  import_types Serge.Web.Schema.CommonTypes
  import_types Serge.Web.Schema.UserTypes
  import_types Serge.Web.Schema.TaskTypes
  import_types Serge.Web.Schema.TeamTypes

  query do
    field :task, :task do
      arg :id, non_null(:id)

      resolve &Resolvers.Task.find/3
    end

    field :tasks, list_of(:task) do
      arg :include_yesterday, :boolean

      resolve &Resolvers.Task.all/3
    end

    field :teams, list_of(:team) do
      resolve &Resolvers.Team.all/3
    end
  end

  mutation do
    field :create_task, :create_task_response do
      arg :tid, non_null(:string)
      arg :label, non_null(:string)
      arg :scheduled_on, :string

      resolve &Resolvers.Task.create/3
    end

    field :update_task, :task do
      arg :id, non_null(:id)
      arg :label, :string
      arg :scheduled_on, :string
      arg :unschedule, :boolean
      arg :completed_on, :string
      arg :uncomplete, :boolean
      arg :before_task_id, :id
      arg :after_task_id, :id

      resolve &Resolvers.Task.update/3
    end

    field :delete_task, :task do
      arg :id, non_null(:id)

      resolve &Resolvers.Task.delete/3
    end
  end
end
