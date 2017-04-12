defmodule Serge.Tasking do
  @min_rank (:math.pow(-2, 31) |> round) - 1
  @default_rank 0
  @max_rank :math.pow(2, 31) |> round

  @moduledoc """
  The boundary for the Tasking system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Serge.Repo
  alias Serge.DateHelpers, as: DH

  alias Serge.Tasking.Task

  @doc """
  Returns the list of Tasks.
  """
  def list_task do
    Repo.all(Task)
  end

  @doc """
  Gets a single task and raise Ecto.NoResultsError if not found.
  """
  def get_task!(id) do
    Repo.get!(Task, id)
  end

  @doc """
  Gets a single task.
  """
  def get_task(id) do
    Repo.get(Task, id)
  end

  @doc """
  Gets a single task for user.
  """
  def get_task(id, user_id: user_id)  do
    scope = Task.for_user_id(Task, user_id)
    Repo.get(scope, id)
  end

  @doc """
  Guess what the previous day of work was.
  """
  def previous_work_day do
    Repo.one(Task.previous_work_day) || DH.yesterday()
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
  end

  @doc """
  Provision a task, intended for seeding.
  """
  def seed_task(attrs) do
    %Task{}
    |> task_seed_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs) do
    task
    |> task_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a task from a task id.
  """
  def update_task_by_id(%{id: id} = attrs, user_id: user_id) do
    case get_task(id, user_id: user_id) do
      nil ->
        changeset = change_task(%Task{})
        { :error, add_error(changeset, :task, "doesn't exist") }
      task ->
        update_task(task, attrs)
    end
  end

  @doc """
  Deletes a Task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Deletes a Task from its id.
  """
  def delete_task(id, user_id: user_id) when is_binary(id) or is_integer(id)  do
    case get_task(id, user_id: user_id) do
      nil ->
        { :error, "Task doesn't exist" }
      task ->
        delete_task(task)
    end
  end

  @doc """
  Deletes all the Tasks.
  """
  def delete_all_tasks() do
    Repo.delete_all(Task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task) do
    task_changeset(task, %{})
  end

  defp task_changeset(%Task{} = task, attrs) do
    task
    |> cast(attrs, [
      :label,
      :scheduled_on,
      :unschedule,
      :completed_on,
      :uncomplete,
      :user_id
    ])
    |> nillify_action(:unschedule, :scheduled_on)
    |> nillify_action(:uncomplete, :completed_on)
    |> set_rank_if_not_set
    |> validate_required([:label, :rank, :user_id])
    |> assoc_constraint(:user)
  end

  defp nillify_action(changeset, action, field) do
    if get_change(changeset, action, false) do
      put_change(changeset, field, nil)
    else
      changeset
    end
  end

  defp set_rank_if_not_set(changeset) do
    if is_nil(get_field(changeset, :user_id)) do
      changeset
    else
      case get_field(changeset, :rank) do
        nil ->
          rank = rank_compared_to_last_task(changeset)
          put_change(changeset, :rank, rank)
        _ ->
          changeset
      end
    end
  end

  defp rank_compared_to_last_task(changeset) do
    scheduled_on = get_field(changeset, :scheduled_on)
    user_id = get_field(changeset, :user_id)
    result =
      Task.last_for_user_and_scheduled_on(user_id, scheduled_on)
      |> select([:rank])
      |> Repo.one
    case result do
      task = %Task{} ->
        (@max_rank - task.rank) / 2 |> round
      _ ->
        @default_rank
    end
  end

  defp task_seed_changeset(%Task{} = task, attrs) do
    task
    |> cast(attrs, [:label, :rank, :completed_on, :scheduled_on, :user_id])
    |> validate_required([:label, :rank, :user_id])
  end
end
