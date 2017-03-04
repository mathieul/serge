defmodule Serge.TaskTest do
  use ExUnit.Case, async: true

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Serge.Repo)
    user = %{id: 12}
    {:ok, [user: user]}
  end

  describe "query tasks" do
    test "it returns an empty array when there are no tasks", ctx do
      doc = "query { tasks { id } }"
      {:ok, %{data: result}} = run(doc, ctx[:user].id)
      assert result["tasks"] == []
    end
  end

  defp run(doc, user_id) do
    Absinthe.run(doc, Serge.Schema, context: %{current_user: %{id: user_id}})
  end
end
