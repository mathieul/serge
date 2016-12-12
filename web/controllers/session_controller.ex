defmodule Serge.SessionController do
  use Serge.Web, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"session" => %{"email" => email, "password" => password}}) do
    case Serge.Auth.login_by_email_and_password(conn, email, password, repo: Repo) do
      {:ok, conn} ->
        logged_in_user = Guardian.Plug.current_resource(conn)
        conn
        |> put_flash(:info, "Welcome back #{logged_in_user.email}")
        |> redirect(to: user_path(conn, :show, logged_in_user))
      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Wrong username / password")
        |> render("new.html")
    end
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out
    |> redirect(to: "/")
  end
end
