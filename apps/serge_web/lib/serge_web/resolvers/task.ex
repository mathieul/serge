defmodule Serge.Web.Resolvers.Task do
  alias Serge.Tasking
  alias Serge.DateHelpers

  def find(_parent, %{ id: id }, %{context: ctx}) do
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

    tasks = Tasking.list_tasks_since(from, user_id: ctx.current_user.id)
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

  defp format_changeset_errors(changeset) do
    evaluated = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    Enum.map(evaluated, fn { attr, message } -> "#{attr} #{message}" end)
  end
end
