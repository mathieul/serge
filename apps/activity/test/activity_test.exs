defmodule ActivityTest do
  use ExUnit.Case

  doctest Activity

  describe "Event.task_created" do
    test "it remembers the task was created" do
      user = %{
        name: "John Zorn",
        avatar_url: "https://avatars.githubusercontent.com/u/5443?v=3"
      }
      task = %{
        label: "My task",
        scheduled_on: Ecto.Date.cast!("2017-03-09"),
        inserted_at: Timex.to_datetime({{2017, 3, 1}, {8, 0, 0}})
      }
      Activity.task_created(task, user: user)

      events = Activity.recent_activity()

      assert Enum.map(events, & &1.avatar_url) == ["https://avatars.githubusercontent.com/u/5443?v=3"]
      assert Enum.map(events, & &1.message) == ["Task \"My task\" scheduled on 3/9/17 by John Zorn."]
    end
  end
end
