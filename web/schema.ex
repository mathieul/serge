defmodule Serge.Schema do
  use Absinthe.Schema

  alias Serge.Resolvers

  import_types Serge.Schema.Types

  query do
    field :user, :user do
      arg :id, non_null(:id)

      resolve &Resolvers.User.find/3
    end

    field :users, list_of(:user) do
      resolve &Resolvers.User.all/3
    end

    field :task, :task do
      arg :id, non_null(:id)

      resolve &Resolvers.Task.find/3
    end

    field :tasks, list_of(:task) do
      resolve &Resolvers.Task.all/3
    end
  end

  mutation do
    field :create_task, :create_task_response do
      arg :tid, non_null(:string)
      arg :label, non_null(:string)
      arg :position, non_null(:integer)
      arg :scheduled_on, non_null(:string)

      resolve &Resolvers.Task.create/3
    end

    field :update_task, :task do
      arg :id, non_null(:id)
      arg :scheduled_on, :string

      resolve &Resolvers.Task.update/3
    end
  end
end
