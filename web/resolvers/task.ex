defmodule Serge.Resolvers.Task do

  alias Serge.Task
  alias Serge.Repo

  def find(_parent, %{ id: id }, _info) do
    case Repo.get(Task, id) do
      nil  -> { :error, "Task id #{id} not found" }
      task -> { :ok, task }
    end
  end

  def all(_parent, _args, %{context: ctx}) do
    tasks = Task.all_ordered_for_user_id(ctx.current_user.id)
      |> Repo.all
      |> Repo.preload(:user)
    { :ok, tasks }
  end

  def create(_parent, attributes, %{context: ctx}) do
    params = Map.put_new(attributes, :user_id, ctx.current_user.id)
    changeset = Task.changeset(%Task{}, params)
    case Repo.insert(changeset) do
      { :ok, task }         -> { :ok, task }
      { :error, changeset } -> { :error, changeset.errors }
    end
  end
end
