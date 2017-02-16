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
    field :create_task, :task do
      arg :label, non_null(:string)
      arg :rank, non_null(:integer)

      resolve &Resolvers.Task.create/3
    end
  end
end
