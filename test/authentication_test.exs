defmodule Serge.UserTest do
  use Serge.ModelCase

  alias Serge.Authentication

  @valid_attrs %{email: "janedoe@example.com", uid: "1qaz2wsx"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    result = Authentication.create_user(@valid_attrs)
    assert elem(result, 0) == :ok
  end

  test "changeset with invalid attributes" do
    result = Authentication.create_user(@invalid_attrs)
    assert elem(result, 0) == :error
  end
end
