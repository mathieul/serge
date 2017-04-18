defmodule Serge.Task.QueryTasksTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory
  alias Serge.DateHelpers, as: DH

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    [user: insert(:user)]
  end

  describe "without arguments" do
    test "it returns an empty array when there are no tasks", ctx do
      doc = "query { tasks { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert result["tasks"] == []
    end

    test "it returns all tasks for the current user when present", ctx do
      insert(:task, user: ctx[:user], label: "One")
      insert(:task, label: "Two")
      insert(:task, user: ctx[:user], label: "Three")
      insert(:task, user: ctx[:user], label: "Four", scheduled_on: nil)

      doc = "query { tasks { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["One", "Three", "Four"]
    end
  end

  describe "includeYesterday: true - requiring tasks completed yesterday" do
    setup ctx do
      three_ago = DH.days_ago(3)
      tasks = %{
        done:      insert(:task, user: ctx[:user], label: "Done 3 days ago", scheduled_on: three_ago, completed_on: three_ago),
        yesterday: insert(:task, user: ctx[:user], label: "Yesterday",       scheduled_on: DH.yesterday),
        today:     insert(:task, user: ctx[:user], label: "Today",           scheduled_on: DH.today),
        tomorrow:  insert(:task, user: ctx[:user], label: "Tomorrow",        scheduled_on: DH.tomorrow),
        later:     insert(:task, user: ctx[:user], label: "Later",           scheduled_on: nil),
      }
      [tasks: tasks]
    end

    test "it doesn't return tasks tasks before yesterday if false", ctx do
      doc = "query { tasks(includeYesterday: false) { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["Today", "Tomorrow", "Later"]
    end

    test "it returns tasks returned 'yesterday' if true", ctx do
      doc = "query { tasks(includeYesterday: true) { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["Done 3 days ago", "Yesterday", "Today", "Tomorrow", "Later"]
    end

    test "it doesn't return tasks completed before 'yesterday'", ctx do
      insert(:task, user: ctx[:user], label: "Done 1 day ago", scheduled_on: DH.days_ago(2), completed_on: DH.days_ago(1))

      doc = "query { tasks(includeYesterday: true) { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["Done 1 day ago", "Yesterday", "Today", "Tomorrow", "Later"]
    end

    test "it also returns tasks completed today when none completed before", ctx do
      Serge.Repo.delete(ctx[:tasks].done)
      insert(:task, user: ctx[:user], label: "Done today", scheduled_on: DH.days_from_now(3), completed_on: DH.today())

      doc = "query { tasks(includeYesterday: true) { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["Yesterday", "Today", "Tomorrow", "Done today", "Later"]
    end
  end

  defp task_labels(result) do
    Enum.map(result["tasks"], fn %{"label" => label} -> label end)
  end
end
