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

alias Serge.{Tasking, Authentication, DateHelpers}

user = Authentication.get_user_by_email!("mathieu@caring.com")

Tasking.delete_all_tasks()

Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled 5 days ago completed 3 days ago",
  scheduled_on: DateHelpers.days_ago(5),
  completed_on: DateHelpers.days_ago(3)
})

Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled today completed 2 days ago",
  scheduled_on: DateHelpers.today,
  completed_on: DateHelpers.days_ago(2)
})

Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled 2 days ago",
  scheduled_on: DateHelpers.days_ago(2),
  completed_on: nil
})

Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled 1 day ago completed today",
  scheduled_on: DateHelpers.days_ago(1),
  completed_on: DateHelpers.today
})

Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled today",
  scheduled_on: DateHelpers.today,
  completed_on: nil
})


Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled tomorrow",
  scheduled_on: DateHelpers.days_from_now(1),
  completed_on: nil
})

Tasking.seed_task(%{
  user_id: user.id,
  label:   "scheduled 7 days from now",
  scheduled_on: DateHelpers.days_from_now(7),
  completed_on: nil
})
