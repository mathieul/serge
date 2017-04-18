defmodule Serge.Task.MutationDeleteTaskTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  @document """
    mutation (
      $id: ID!
    ) {
      deleteTask(
        id: $id
      ) {
        id
        label
      }
    }
  """

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    user = insert(:user)
    [
      user: user,
      task: insert(:task, user: user, label: "Ze label", rank: 1, scheduled_on: "2017-01-11")
    ]
  end

  test "it deletes the task if it exists", ctx do
    {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id})
    assert get_in(result, ["deleteTask", "id"]) == "#{ctx[:task].id}"
    assert Serge.Tasking.get_task(ctx[:task].id) == nil
  end

  test "it returns an error if the task doesn't exist", ctx do
    {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{"id" => "0"})
    assert Enum.all?(errors, &(Regex.match?(~r/Task doesn't exist/, &1.message)))
  end

  test "it returns an error if the task doesn't belong to the user", ctx do
    other_task = insert(:task, user: insert(:user))
    {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{"id" => other_task.id})
    assert Enum.all?(errors, &(Regex.match?(~r/Task doesn't exist/, &1.message)))
  end
end
