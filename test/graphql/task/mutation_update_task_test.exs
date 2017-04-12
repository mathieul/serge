defmodule Serge.Task.MutationUpdateTaskTest do
  use Serge.GraphqlCase, async: true
  import Serge.Factory

  @document """
      mutation (
        $id: ID!,
        $label: String,
        $scheduledOn: String
        $completedOn: String
      ) {
        updateTask(
          id: $id,
          label: $label,
          scheduledOn: $scheduledOn
          completedOn: $completedOn
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
      task: insert(:task, user: user, label: "Old label", rank: 3, scheduled_on: "2017-01-11")
    ]
  end

  describe "with valid attributes" do
    test "it can update the label", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "label" => "New label"})
      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-11"
      assert get_in(result, ["updateTask", "label"]) == "New label"
    end

    test "it can update the scheduled date", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "scheduledOn" => "2017-01-01"})
      assert get_in(result, ["updateTask", "label"]) == "Old label"
      assert get_in(result, ["updateTask", "scheduledOn"]) == "2017-01-01"
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "scheduled" => false})
      assert get_in(result, ["updateTask", "scheduledOn"]) == nil
    end

    test "it can update the completed date", ctx do
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "completedOn" => "2017-12-31"})
      assert get_in(result, ["updateTask", "rank"]) == 3
      assert get_in(result, ["updateTask", "completedOn"]) == "2017-12-31"
      {:ok, %{data: result}} = run(@document, ctx[:user].id, %{"id" => ctx[:task].id, "completed" => false})
      assert get_in(result, ["updateTask", "completedOn"]) == nil
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
        "scheduled_on" => "not-a-valid-date"
      })
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "scheduled_on"/, &1.message)))
    end

    test "it returns an error if completed date is invalid", ctx do
      {:ok, %{errors: errors}} = run(@document, ctx[:user].id, %{
        "id" => ctx[:task].id,
        "completed_on" => "not-a-valid-date"
      })
      assert Enum.all?(errors, &(Regex.match?(~r/^In argument "completed_on"/, &1.message)))
    end
  end
end
