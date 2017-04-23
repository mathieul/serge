defmodule Activity do
  import Ecto.{Query, Changeset}, warn: false
  alias Activity.{Repo, Event}

  def task_created(task, user: user) do
  end

  def recent() do
    []
  end

  def event_changeset(%Event{} = event, attrs) do
    event
    |> cast(attrs, [:user_name, :avatar_url, :message])
    |> validate_required([:user_name, :message])
  end
end
