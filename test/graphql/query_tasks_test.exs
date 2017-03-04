defmodule Serge.TaskTest do
  use ExUnit.Case, async: true
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

      doc = "query { tasks { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["One", "Three"]
    end
  end

  describe "completedYesterday: true - requiring tasks completed yesterday" do
    setup ctx do
      tasks = %{
        done:      insert(:task, user: ctx[:user], label: "Done 3 days ago", completed_on: DH.days_ago(3)),
        yesterday: insert(:task, user: ctx[:user], label: "Yesterday", scheduled_on: DH.yesterday),
        today:     insert(:task, user: ctx[:user], label: "Today",     scheduled_on: DH.today),
        tomorrow:  insert(:task, user: ctx[:user], label: "Tomorrow",  scheduled_on: DH.tomorrow),
      }
      [tasks: tasks]
    end

    test "it doesn't return tasks completed if false", ctx do
      doc = "query { tasks(completedYesterday: false) { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert task_labels(result) == ["Yesterday", "Today", "Tomorrow"]
    end
  end

  defp task_labels(result) do
    Enum.map(result["tasks"], fn %{"label" => label} -> label end)
  end

  defp run(doc, user_id) do
    Absinthe.run(doc, Serge.Schema, context: %{current_user: %{id: user_id}})
  end
end
