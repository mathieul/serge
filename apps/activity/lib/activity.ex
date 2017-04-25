defmodule Activity do
  @moduledoc """
  The boundary for the Activity application.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias Activity.{Repo, Event}

  @doc """
  Creates a :task_created event.
  """
  def task_created(task) do
    name = name_or_email(task.user)
    message = "Task #{inspect task.label} scheduled #{humanize_schedule(task.scheduled_on, "on", "for later")} by #{name}."
    trigger_task_event("task_created", task, message)
  end

  @doc """
  Creates a :task_rescheduled event.
  """
  def task_rescheduled(task, scheduled_on) do
    name = name_or_email(task.user)
    message = "Task #{inspect task.label} rescheduled #{humanize_schedule(scheduled_on, "to", "to later")} by #{name}."
    trigger_task_event("task_rescheduled", task, message)
  end

  @doc """
  Returns the last 20 events.
  """
  def recent_activity() do
    Event.recent
    |> limit(10)
    |> Repo.all
  end

  defp trigger_task_event(operation, task, message) do
    attrs = %{
      operation:  operation,
      user_name:  name_or_email(task.user),
      avatar_url: task.user.avatar_url,
      message:    message
    }

    {:ok, _} =
      %Event{}
      |> event_changeset(attrs)
      |> Repo.insert

    task
  end

  defp humanize_schedule(scheduled_on, prefix, later) do
    case scheduled_on do
      nil ->
        later
      time ->
        formatted_time = Timex.format!(time, "%-m/%-d/%y", :strftime)
        "#{prefix} #{formatted_time}"
    end
  end

  defp event_changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:operation, :user_name, :avatar_url, :message])
    |> validate_required([:operation, :user_name, :message])
  end

  defp name_or_email(user) do
    user.name || user.email
  end
end
