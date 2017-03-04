defmodule Serge.TaskTest do
  use Serge.ModelCase

  alias Serge.Task

  @valid_attrs %{completed: false, label: "some content", rank: 42, scheduled_on: "2017-03-09", user_id: 12}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Task.changeset(%Task{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Task.changeset(%Task{}, @invalid_attrs)
    refute changeset.valid?
  end
end
