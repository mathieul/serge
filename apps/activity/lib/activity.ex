defmodule Activity do
  import Ecto.{Query, Changeset}, warn: false
  alias Activity.{Repo, Event}

  def task_created(task, user: user) do
    scheduled_on = case task.scheduled_on do
      nil ->
        "for later"
      time ->
        formatted_time = Timex.format!(time, "%-m/%-d/%y", :strftime)
        "on #{formatted_time}"
    end
    attrs = %{
      operation: :task_created,
      user_name: user.name,
      avatar_url: user.avatar_url,
      message: "Task #{inspect task.label} scheduled #{scheduled_on} by #{user.name}."
    }
    %Event{}
    |> event_changeset(attrs)
    |> Repo.insert
  end

  def recent_activity() do
    Event.recent
    |> limit(10)
    |> Repo.all
  end

  defp event_changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:user_name, :avatar_url, :message])
    |> validate_required([:user_name, :message])
  end
end
