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
    avatar_url = task.user.avatar_url
    user_name  = user_name_or_email(task.user)
    attrs = %{
      operation: "task_created",
      user_name: user_name,
      avatar_url: avatar_url,
      message:  "Task #{inspect task.label} scheduled #{humanize_schedule(task.scheduled_on, "on", "for later")} by #{user_name}."
    }
    {:ok, _} = %Event{}
    |> event_changeset(attrs)
    |> Repo.insert

    task
  end

  @doc """
  Creates a :task_rescheduled event.
  """
  def task_rescheduled(task, scheduled_on) do
    avatar_url = task.user.avatar_url
    user_name  = user_name_or_email(task.user)
    attrs = %{
      operation: "task_rescheduled",
      user_name: user_name,
      avatar_url: avatar_url,
      message:  "Task #{inspect task.label} rescheduled #{humanize_schedule(scheduled_on, "to", "to later")} by #{user_name}."
    }
    {:ok, _} = %Event{}
    |> event_changeset(attrs)
    |> Repo.insert

    task
  end

  @doc """
  Returns the last 20 events.
  """
  def recent_activity() do
    Event.recent
    |> limit(10)
    |> Repo.all
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

  defp user_name_or_email(user) do
    user.name || user.email
  end
end
