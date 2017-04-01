defmodule Serge.Tasking do
  @moduledoc """
  The boundary for the Tasking system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Serge.Repo
  alias Serge.DateHelpers

  alias Serge.Tasking.Task

  @doc """
  Returns the list of task.
  """
  def list_task do
    Repo.all(Task)
  end

  @doc """
  Gets a single task and raise Ecto.NoResultsError if not found.
  """
  def get_task!(id), do: Repo.get!(Task, id)

  @doc """
  Gets a single task.
  """
  def get_task(id) do
    case Repo.get(Task, id) do
      nil ->
        nil
      task ->
        Task.infer_completed(task)
    end
  end

  @doc """
  Guess what the previous day of work was.
  """
  def previous_work_day do
    Repo.one(Task.previous_work_day) || DateHelpers.yesterday()
  end

  @doc """
  Guess what the previous day of work was.
  """
  def list_tasks_since(date, user_id: user_id) do
    Task.starting_from(date)
    |> Task.for_user_id(user_id)
    |> Task.ordered_by_schedule_and_rank()
    |> Repo.all()
    |> Repo.preload(:user)
    |> Enum.map(&Task.infer_completed/1)
  end

  @doc """
  Creates a task for a user.
  """
  def create_task(attrs, user_id: user_id) do
    attrs = Map.put_new(attrs, :user_id, user_id)
    create_task(attrs)
  end

  @doc """
  Creates a task.
  """
  def create_task(attrs \\ %{}) do
    %Task{}
    |> task_changeset(attrs)
    |> Repo.insert()
    |> infer_task_if_ok
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> task_changeset(attrs)
    |> Repo.update()
    |> infer_task_if_ok
  end

  @doc """
  Updates a task from a task id.
  """
  def update_task_by_id(%{id: id} = attrs) do
    task = get_task!(id)
    update_task(task, attrs)
  end

  @doc """
  Deletes a Task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
    |> infer_task_if_ok
  end

  @doc """
  Deletes a Task from its id.
  """
  def delete_task(id) when is_binary(id) or is_integer(id)  do
    get_task!(id) |> delete_task
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task) do
    task_changeset(task, %{})
  end

  defp infer_task_if_ok(result) do
    case result do
      { :ok, task } ->
        { :ok, Task.infer_completed(task) }
      error ->
        error
    end
  end

  defp task_changeset(%Task{} = task, attrs) do
    task
    |> cast(attrs, [:label, :completed, :scheduled_on, :position, :user_id])
    |> Task.ordered
    |> Task.update_completed_on
    |> validate_required([:label, :scheduled_on, :user_id])
    |> assoc_constraint(:user)
  end
end
