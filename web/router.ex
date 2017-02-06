defmodule Serge.Router do
  use Serge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_user
  end

  pipeline :authenticated do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_current_user
    plug :redirect_if_not_authenticated
  end

  scope "/", Serge do
    pipe_through :browser

    get "/", HomeController, :index
  end

  scope "/", Serge do
    pipe_through :authenticated

    get "/authenticated", HomeController, :authenticated
  end

  scope "/auth", Serge do
    pipe_through :browser

    get "/:provider", AuthController, :index
    get "/:provider/callback", AuthController, :callback
    delete "/logout", AuthController, :delete
  end

  # Fetch the current user from the session and add it to `conn.assigns`. This
  # will allow you to have access to the current user in your views with
  # `@current_user`.
  defp assign_current_user(conn, _) do
    current_user = get_session(conn, :current_user)
    assign(conn, :current_user, current_user)
  end

  defp redirect_if_not_authenticated(conn, _) do
    if get_session(conn, :current_user) do
      conn
    else
      conn
      |> put_flash(:error, "You need to be signed in to view this page")
      |> redirect(to: "/")
    end
  end
end
