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
  end

  # mutation do
  # end
end
