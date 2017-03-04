defmodule Serge.TaskTest do
  use ExUnit.Case, async: true
  import Serge.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    {:ok, [user: insert(:user)]}
  end

  describe "query tasks" do
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
      labels = Enum.map(result["tasks"], fn %{"label" => label} -> label end)
      assert labels == ["One", "Three"]
    end
  end

  defp run(doc, user_id) do
    Absinthe.run(doc, Serge.Schema, context: %{current_user: %{id: user_id}})
  end
end
