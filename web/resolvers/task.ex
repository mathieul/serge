defmodule Serge.Resolvers.Task do

  alias Serge.Task
  alias Serge.Repo

  def find(_parent, %{ id: id }, _info) do
    case Repo.get(Task, id) do
      nil  -> { :error, "Task id #{id} not found" }
      task -> { :ok, task }
    end
  end

  def all(_parent, args, %{context: ctx}) do
    from = if args[:completed_yesterday] do
      Repo.one(Task.guess_yesterdays_work_day)
    else
      nil
    end

    scope = if from do
      Task.including_completed_from(from)
    else
      Task.excluding_completed
    end
    tasks =
      scope
      |> Task.ordered_for_user_id(ctx.current_user.id)
      |> Repo.all
      |> Repo.preload(:user)
      |> Enum.map(&Task.infer_completed/1)
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
        { :ok, %{ tid: tid, task: Task.infer_completed(task) } }

      { :error, changeset } ->
        { :error, changeset.errors }
    end
  end

  def update(_parent, attributes, _info) do
    task = Repo.get!(Task, attributes[:id])
    changeset = Task.changeset(task, attributes)

    case Repo.update(changeset) do
      { :ok, task } ->
        {:ok, Task.infer_completed(task) }

      { :error, changeset } ->
        { :error, changeset.errors }
    end
  end
end
