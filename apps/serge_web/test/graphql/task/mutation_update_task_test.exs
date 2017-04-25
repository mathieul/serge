defmodule Serge.Task.MutationUpdateTaskTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  @document """
      mutation (
        $id: ID!,
        $label: String,
        $scheduledOn: String,
        $unschedule: Boolean,
        $completedOn: String,
        $uncomplete: Boolean
        $afterTaskId: ID,
        $beforeTaskId: ID
      ) {
        updateTask(
          id: $id,
          label: $label,
          scheduledOn: $scheduledOn,
          unschedule: $unschedule,
          completedOn: $completedOn,
          uncomplete: $uncomplete,
          afterTaskId: $afterTaskId,
          beforeTaskId: $beforeTaskId
        ) {
          id
          label
          rank
          scheduledOn
          completedOn
        }
      }
    """

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    user = insert(:user)
    [
      user: user,
      task: insert(:task, user: user, label: "Old label", scheduled_on: "2017-01-11")
    ]
  end

  describe "with valid attributes" do
    test "it can update the label", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "label" => "New label"})
      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-11"
      assert get_in(result, ["updateTask", "label"]) == "New label"
    end

    test "it can update the scheduled date (no other task for that date)", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "scheduledOn" => "2017-01-01"})
      assert get_in(result, ["updateTask", "label"]) == "Old label"
      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-01"
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "unschedule" => true})
      assert get_in(result, ["updateTask", "scheduledOn"]) == nil
    end

    test "it can update the scheduled date (at least one other task for that date)", ctx do
      insert(:task, user: ctx[:user], rank: 0, scheduled_on: "2017-01-01")
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "scheduledOn" => "2017-01-01"})
      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-01"
      assert get_in(result, ["updateTask", "rank"]) == 1073741824
    end

    test "it can update the completed date", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "completedOn" => "2017-12-31"})
      assert get_in(result, ["updateTask", "label"]) == "Old label"
      assert get_in(result, ["updateTask", "completedOn"]) == "2017-12-31"
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "uncomplete" => true})
      assert get_in(result, ["updateTask", "completedOn"]) == nil
    end

    test "it triggers a :task_rescheduled event when scheduledOn changes", ctx do
      :mnesia.clear_table(:events)
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "scheduledOn" => "2017-01-01"})

      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-01"
      events = Activity.recent_activity()
      assert length(events) == 1
      assert List.first(events).operation == "task_rescheduled"
    end

    test "it doesn't trigger a :task_rescheduled event when scheduledOn doesn't change", ctx do
      :mnesia.clear_table(:events)
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "completedOn" => "2017-12-31"})

      assert get_in(result, ["updateTask", "completedOn"]) == "2017-12-31"
      assert Activity.recent_activity() == []
    end
  end

  describe "with invalid attributes" do
    test "it returns an error if the label is invalid", ctx do
      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "label" => 42})
      assert Enum.all?(errors, &(Regex.match?(~r/^Argument "label" has invalid value/, &1.message)))
    end

    test "it returns an error if scheduled date is invalid", ctx do
      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "scheduledOn" => "not-a-valid-date"
      })
      assert Enum.all?(errors, &(Regex.match?(~r/scheduled_on is invalid/, &1.message)))
    end

    test "it returns an error if completed date is invalid", ctx do
      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "completedOn" => "not-a-valid-date"
      })
      assert Enum.all?(errors, &(Regex.match?(~r/completed_on is invalid/, &1.message)))
    end
  end

  describe "when the task is not found" do
    test "it returns an error if the task doesn't exist", ctx do
      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{"id" => "0", "label" => "Trying"})
      assert Enum.any?(errors, &(Regex.match?(~r/task doesn't exist/, &1.message)))
    end

    test "it returns an error if the task belongs to another user", ctx do
      other_task = insert(:task, user: insert(:user))
      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{"id" => other_task.id, "label" => "Trying"})
      assert Enum.any?(errors, &(Regex.match?(~r/task doesn't exist/, &1.message)))
    end
  end

  describe "changing task order" do
    test "it can order a task before another task (other is first)", ctx do
      other = insert(:task, user: ctx[:user], rank: 0, scheduled_on: "2017-01-01")
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "beforeTaskId" => other.id
      })
      assert get_in(result, ["updateTask", "rank"]) == -1073741825
      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-01"
    end

    test "it can order a task before another task (other has more before)", ctx do
      insert(:task, user: ctx[:user], rank: 0, scheduled_on: "2017-01-01")
      other = insert(:task, user: ctx[:user], rank: 1073741824, scheduled_on: "2017-01-01")
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "beforeTaskId" => other.id
      })
      assert get_in(result, ["updateTask", "rank"]) == 536870912
    end

    test "it can order a task after another task (other is last)", ctx do
      other = insert(:task, user: ctx[:user], rank: 0, scheduled_on: "2017-01-01")
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "afterTaskId" => other.id
      })
      assert get_in(result, ["updateTask", "rank"]) == 1073741824
    end

    test "it can order a task after another task (other has more after)", ctx do
      other = insert(:task, user: ctx[:user], rank: 1073741824, scheduled_on: "2017-01-01")
      insert(:task, user: ctx[:user], rank: 1610612736, scheduled_on: "2017-01-01")
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "afterTaskId" => other.id
      })
      assert get_in(result, ["updateTask", "rank"]) == 1342177280
    end
  end
end
