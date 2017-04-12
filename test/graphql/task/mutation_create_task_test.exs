defmodule Serge.Task.MutationCreateTaskTest do
  use Serge.GraphqlCase, async: true
  import Serge.Factory

  @document """
      mutation (
        $tid: String!,
        $label: String!,
        $scheduledOn: String!
      ) {
        createTask(
          tid: $tid,
          label: $label,
          scheduledOn: $scheduledOn
        ) {
          tid
          task {
            id
            label
            rank
            scheduledOn
            completedOn
          }
        }
      }
    """

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    [
      user: insert(:user),
      variables: %{
        "tid" => "tmp42",
        "label" => "that thing to do",
        "scheduledOn" => "2017-03-09"
      }
    ]
  end

  describe "with valid attributes" do
    test "it creates a task passing a temporary id", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, ctx[:variables])
      assert get_in(result, ["createTask", "tid"]) == "tmp42"
      assert get_in(result, ["createTask", "task", "label"]) == "that thing to do"
      assert get_in(result, ["createTask", "task", "scheduledOn"]) == "2017-03-09"
      assert get_in(result, ["createTask", "task", "completedOn"]) == nil
    end

    test "it can create a task without a schedule date", ctx do
      variables = Map.drop(ctx[:variables], ["scheduledOn"])

      {:ok, %{data: result}} = run(@document, ctx[:user].id, variables)
      assert get_in(result, ["createTask", "tid"]) == "tmp42"
      assert get_in(result, ["createTask", "task", "label"]) == "that thing to do"
      assert get_in(result, ["createTask", "task", "scheduledOn"]) == nil
      assert get_in(result, ["createTask", "task", "completedOn"]) == nil
    end
  end

  describe "with invalid attributes" do
    test "it returns an error if tid is missing", ctx do
      variables = Map.drop(ctx[:variables], ["tid"])

      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, variables)
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "tid"/, &1.message)))
    end

    test "it returns an error if label is missing", ctx do
      variables = Map.drop(ctx[:variables], ["label"])

      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, variables)
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "label"/, &1.message)))
    end

    test "it returns an error if scheduled date is invalid", ctx do
      variables = Map.put(ctx[:variables], "scheduled_on", "not-a-valid-date")

      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, variables)
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "scheduled_on"/, &1.message)))
    end
  end
end
