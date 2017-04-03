defmodule Serge.Task.QueryTaskTest do
  use ExUnit.Case, async: true
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
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert result == %{"task" => nil}
    end
  end

  defp run(doc, user_id) do
    Absinthe.run(doc, Serge.Web.Schema, context: %{current_user: %{id: user_id}})
  end
end
