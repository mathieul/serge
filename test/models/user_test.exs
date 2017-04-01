defmodule Serge.UserTest do
  use Serge.ModelCase

  alias Serge.Web.User

  @valid_attrs %{email: "janedoe@example.com", uid: "1qaz2wsx"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end
end
