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

  def create(_parent, attributes = %{tid: tid}, %{context: ctx}) do
    params =
      attributes
      |> Map.put_new(:user_id, ctx.current_user.id)
      |> Map.delete(:tid)

    changeset = Task.changeset(%Task{}, params)
    case Repo.insert(changeset) do
      { :ok, task } ->
        { :ok, %{ tid: tid, task: task } }

      { :error, changeset } ->
        { :error, changeset.errors }
    end
  end
end
