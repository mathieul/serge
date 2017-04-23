defmodule ActivityTest do
  use ExUnit.Case

  doctest Event

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
      assert events == [%{
        avatar_url: "https://avatars.githubusercontent.com/u/5443?v=3",
        message: "John Zorn created a new task scheduled for 3/9/17",
        datetime: {{2017, 3, 1}, {8, 0, 0}}
      }]
    end
  end
end

# Documentation:
#   * http://erlang.org/doc/man/ets.html#select-3
#   * https://elixirschool.com/lessons/specifics/ets/
#
# :ets.new(:activities, [:ordered_set, :protected, :named_table])
#
# :ets.insert :activities, {(Timex.now |> Timex.format!("%FT%T%:z", :strftime)), "metallica", [:blah]}
# :ets.insert :activities, {(Timex.now |> Timex.format!("%FT%T%:z", :strftime)), "iron maiden", [:okok]}
# :ets.insert :activities, {(Timex.now |> Timex.format!("%FT%T%:z", :strftime)), "slayer", [:arghhhh]}
#
# {list, _} = :ets.select_reverse :activities, [{{:"$1",:"$2",:"$3"},[],[:"$_"]}], 2
