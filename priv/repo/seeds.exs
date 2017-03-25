# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Serge.Repo.insert!(%Serge.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Serge.{Repo, Task, User, DateHelpers}

user = Repo.one!(User.find_by_email("mathieu@caring.com"))

Repo.delete_all(Task)

%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled 5 days ago completed 3 days ago",
        position: 0,
        scheduled_on: DateHelpers.days_ago(5),
        completed_on: DateHelpers.days_ago(3)
      })
  |> Repo.insert!

%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled today completed 2 days ago",
        position: 1,
        scheduled_on: DateHelpers.today,
        completed_on: DateHelpers.days_ago(2)
      })
  |> Repo.insert!

%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled 2 days ago",
        position: 2,
        scheduled_on: DateHelpers.days_ago(2),
        completed_on: nil
      })
  |> Repo.insert!

%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled 1 day ago completed today",
        position: 3,
        scheduled_on: DateHelpers.days_ago(1),
        completed_on: DateHelpers.today
      })
  |> Repo.insert!

%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled today",
        position: 4,
        scheduled_on: DateHelpers.today,
        completed_on: nil
      })
  |> Repo.insert!


%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled tomorrow",
        position: 5,
        scheduled_on: DateHelpers.days_from_now(1),
        completed_on: nil
      })
  |> Repo.insert!

%Task{}
  |> Task.admin_changeset(%{
        user_id: user.id,
        label:   "scheduled 7 days from now",
        position: 6,
        scheduled_on: DateHelpers.days_from_now(7),
        completed_on: nil
      })
  |> Repo.insert!
