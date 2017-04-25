defmodule ActivityTest do
  use ExUnit.Case

  doctest Activity

  setup do
    :mnesia.clear_table(:events)
    :mnesia.clear_table(:id_seq)

    user = %{
      name: "John Zorn",
      avatar_url: "https://myurl.example.com"
    }
    %{user: user}
  end

  test "Event.task_created", %{user: user} do
    task = %{
      label: "My task",
      scheduled_on: Ecto.Date.cast!("2017-03-09"),
      inserted_at: Timex.to_datetime({{2017, 3, 1}, {8, 0, 0}}),
      user: user
    }
    returned = Activity.task_created(task)
    assert returned == task

    events = Activity.recent_activity()

    assert Enum.map(events, & &1.operation) == ["task_created"]
    assert Enum.map(events, & &1.avatar_url) == ["https://myurl.example.com"]
    assert Enum.map(events, & &1.message) == ["Task \"My task\" scheduled on 3/9/17 by John Zorn."]
  end

  test "Event.task_rescheduled", %{user: user} do
    task = %{
      label: "My task",
      updated_at: Timex.to_datetime({{2017, 3, 8}, {17, 0, 0}}),
      user: user
    }
    returned = Activity.task_rescheduled(task, Ecto.Date.cast!("2017-03-29"))
    assert returned == task

    events = Activity.recent_activity()

    assert Enum.map(events, & &1.operation) == ["task_rescheduled"]
    assert Enum.map(events, & &1.avatar_url) == ["https://myurl.example.com"]
    assert Enum.map(events, & &1.message) == ["Task \"My task\" rescheduled to 3/29/17 by John Zorn."]
  end
end
