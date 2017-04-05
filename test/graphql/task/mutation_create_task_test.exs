defmodule Serge.Task.MutationCreateTaskTest do
  use Serge.GraphqlCase, async: true
  import Serge.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    [user: insert(:user)]
  end

  describe "with valid attributes" do
    test "it creates a task passing a temporary id", ctx do
      doc = """
      mutation {
        createTask(
          tid: "tmp42",
          label: "that thing to do",
          position: 1,
          scheduledOn: "2017-03-09"
          ) {
          tid
          task {
            id
            label
            rank
            scheduledOn
            completed
            completedOn
          }
        }
      }
      """
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert get_in(result, ["createTask", "tid"]) == "tmp42"
      assert get_in(result, ["createTask", "task", "label"]) == "that thing to do"
      assert get_in(result, ["createTask", "task", "scheduledOn"]) == "2017-03-09"
      assert get_in(result, ["createTask", "task", "completed"]) == false
      assert get_in(result, ["createTask", "task", "completedOn"]) == nil
    end
  end
end
