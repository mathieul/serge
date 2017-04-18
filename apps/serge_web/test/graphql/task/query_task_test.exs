defmodule Serge.Task.QueryTaskTest do
  use Serge.Web.GraphqlCase, async: true
  import Serge.Factory

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    [user: insert(:user)]
  end

  describe "when the task exists" do
    setup ctx do
      [
        mine: insert(:task, user: ctx[:user], label: "Mine"),
        theirs: insert(:task, label: "Theirs")
      ]
    end

    test "it returns the task when it is mine", ctx do
      doc = "query { task(id: #{ctx[:mine].id}) { label } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert result == %{"task" => %{"label" => "Mine"}}
    end

    test "it returns an error when it is theirs", ctx do
      doc = "query { task(id: #{ctx[:theirs].id}) { label } }"
      {:ok, %{data: result, errors: errors}} = run(doc, ctx[:user].id)
      assert result == %{"task" => nil}
      assert Enum.map(errors, &(&1.message)) == [~s{In field "task": Task id #{ctx[:theirs].id} not found}]
    end
  end

  describe "when the task doesn't exist" do
    test "it returns an error", ctx do
      doc = "query { task(id: \"42\") { label } }"
      {:ok, %{data: result, errors: errors}} = run(doc, ctx[:user].id)
      assert result == %{"task" => nil}
      assert Enum.map(errors, &(&1.message)) == [~s{In field "task": Task id 42 not found}]
    end
  end
end
