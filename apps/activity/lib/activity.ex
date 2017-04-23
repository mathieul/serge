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
    user = task.user
    attrs = %{
      operation: :task_created,
      user_name: user.name,
      avatar_url: user.avatar_url,
      message:  "Task #{inspect task.label} scheduled #{humanize_schedule(task)} by #{user.name}."
    }
    %Event{}
    |> event_changeset(attrs)
    |> Repo.insert

    task
  end

  @doc """
  Returns the last 20 events.
  """
  def recent_activity() do
    Event.recent
    |> limit(20)
    |> Repo.all
  end

  defp humanize_schedule(source) do
    case source.scheduled_on do
      nil ->
        "for later"
      time ->
        formatted_time = Timex.format!(time, "%-m/%-d/%y", :strftime)
        "on #{formatted_time}"
    end
  end

  defp event_changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:user_name, :avatar_url, :message])
    |> validate_required([:user_name, :message])
  end
end
