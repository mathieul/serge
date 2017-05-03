defmodule Serge.Web.TeamControllerTest do
  use Serge.Web.ConnCase

  alias Serge.Web.Scrumming

  @create_attrs %{name: "some name"}
  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:team) do
    {:ok, team} = Web.Scrumming.create_team(@create_attrs)
    team
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, team_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing Teams"
  end

  test "renders form for new teams", %{conn: conn} do
    conn = get conn, team_path(conn, :new)
    assert html_response(conn, 200) =~ "New Team"
  end

  test "creates team and redirects to show when data is valid", %{conn: conn} do
    conn = post conn, team_path(conn, :create), team: @create_attrs

    assert %{id: id} = redirected_params(conn)
    assert redirected_to(conn) == team_path(conn, :show, id)

    conn = get conn, team_path(conn, :show, id)
    assert html_response(conn, 200) =~ "Show Team"
  end

  test "does not create team and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, team_path(conn, :create), team: @invalid_attrs
    assert html_response(conn, 200) =~ "New Team"
  end

  test "renders form for editing chosen team", %{conn: conn} do
    team = fixture(:team)
    conn = get conn, team_path(conn, :edit, team)
    assert html_response(conn, 200) =~ "Edit Team"
  end

  test "updates chosen team and redirects when data is valid", %{conn: conn} do
    team = fixture(:team)
    conn = put conn, team_path(conn, :update, team), team: @update_attrs
    assert redirected_to(conn) == team_path(conn, :show, team)

    conn = get conn, team_path(conn, :show, team)
    assert html_response(conn, 200) =~ "some updated name"
  end

  test "does not update chosen team and renders errors when data is invalid", %{conn: conn} do
    team = fixture(:team)
    conn = put conn, team_path(conn, :update, team), team: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit Team"
  end

  test "deletes chosen team", %{conn: conn} do
    team = fixture(:team)
    conn = delete conn, team_path(conn, :delete, team)
    assert redirected_to(conn) == team_path(conn, :index)
    assert_error_sent 404, fn ->
      get conn, team_path(conn, :show, team)
    end
  end
end
