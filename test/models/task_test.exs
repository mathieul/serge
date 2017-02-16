defmodule Serge.TaskTest do
  use Serge.ModelCase

  alias Serge.Task

  @valid_attrs %{completed_at: %{day: 17, hour: 14, min: 0, month: 4, sec: 0, year: 2010}, label: "some content", rank: 42}
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
