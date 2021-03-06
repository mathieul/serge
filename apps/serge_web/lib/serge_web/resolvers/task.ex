defmodule Serge.Web.Resolvers.Task do
  import Serge.Web.Resolvers.Helpers, only: [format_changeset_errors: 1]

  alias Serge.Tasking
  alias Serge.DateHelpers

  def find(_parent, %{id: id}, %{context: ctx}) do
    case Tasking.get_task(id, user_id: ctx.current_user.id) do
      nil ->
        { :error, "Task id #{id} not found" }
      task ->
        { :ok, task }
    end
  end

  def all(_parent, args, %{context: ctx}) do
    from = if args[:include_yesterday] do
      Tasking.previous_work_day()
    else
      DateHelpers.today()
    end

    tasks = Tasking.list_pending_tasks_and_completed_since(from, user_id: ctx.current_user.id)
    { :ok, tasks }
  end

  def create(_parent, attributes = %{tid: tid}, %{context: ctx}) do
    case Tasking.create_task(attributes, user_id: ctx.current_user.id) do
      { :ok, task } ->
        { :ok, %{ tid: tid, task: task } }

      { :error, changeset } ->
        { :error, format_changeset_errors(changeset) }
    end
  end

  def update(_parent, attributes, %{context: ctx}) do
    case Tasking.update_task_by_id(attributes, user_id: ctx.current_user.id) do
      { :error, changeset } ->
        { :error, format_changeset_errors(changeset) }
      ok ->
        ok
    end
  end

  def delete(_parent, %{id: id}, %{context: ctx}) do
    case Tasking.delete_task(id, user_id: ctx.current_user.id) do
      { :error, message } ->
        { :error, [message] }
      ok ->
        ok
    end
  end
end
