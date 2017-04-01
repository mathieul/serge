defmodule Serge.Web.Resolvers.User do

  alias Serge.Authentication.User
  alias Serge.Repo

  def find(_parent, %{ id: id }, _info) do
    case Repo.get(User, id) do
      nil  -> { :error, "User id #{id} not found" }
      user -> { :ok, user }
    end
  end

  def all(_parent, _args, _info) do
    { :ok, Repo.all(User) }
  end
end
