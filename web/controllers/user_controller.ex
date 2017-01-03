defmodule Serge.UserController do
  use Serge.Web, :controller
  alias Serge.User

  def new(conn, _params) do
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    changeset = User.registration_changeset(%User{}, user_params)
    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> Serge.Auth.login(user)
        |> put_flash(:info, "User created")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        conn
        |> render("new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Repo.get(User, id)
    if user == Guardian.Plug.current_resource(conn) do
      render(conn, "show.html", user: user)
    else
      conn
      |> put_flash(:info, "No access")
      |> redirect(to: "/")
    end
  end
end
