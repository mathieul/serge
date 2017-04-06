defmodule Serge.Task.MutationCreateTaskTest do
  use Serge.GraphqlCase, async: true
  import Serge.Factory

  @document """
      mutation (
        $tid: String!,
        $label: String!,
        $position: Int!,
        $scheduledOn: String!
      ) {
        createTask(
          tid: $tid,
          label: $label,
          position: $position,
          scheduledOn: $scheduledOn
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

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    [
      user: insert(:user),
      variables: %{
        "tid" => "tmp42",
        "label" => "that thing to do",
        "position" => 1,
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
      assert get_in(result, ["createTask", "task", "completed"]) == false
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

    test "it returns an error if position is missing", ctx do
      variables = Map.drop(ctx[:variables], ["position"])

      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, variables)
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "position"/, &1.message)))
    end

    test "it returns an error if scheduledOn is missing", ctx do
      variables = Map.drop(ctx[:variables], ["scheduledOn"])

      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, variables)
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "scheduledOn"/, &1.message)))
    end
  end
end
