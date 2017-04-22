defmodule ActivityTest do
  use ExUnit.Case
  doctest Activity

  describe "Activity.task_created" do
    test "it remembers the task was created" do
      user = %{
        name: "John Zorn",
        avatar_url: "https://avatars.githubusercontent.com/u/5443?v=3"
      }
      task = %{
        label: "My task",
        scheduled_on: Ecto.Date.cast!("2017-03-09"),
        inserted_at: Timex.to_datetime({{2017, 3, 1}, {8, 0, 0}}),
        user: user
      }
      Activity.task_created(task)

      events = Activity.recent_activity()
      assert events == [%{
        avatar_url: "https://avatars.githubusercontent.com/u/5443?v=3",
        message: "John Zorn created a new task scheduled for 3/9/17",
        datetime: {{2017, 3, 1}, {8, 0, 0}}
      }]
    end
  end
end
