defmodule Serge.Router do
  use Serge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_user_and_token
  end

  scope "/", Serge do
    pipe_through :browser

    get "/", HomeController, :index
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
  defp assign_user_and_token(conn, _) do
    access_token = get_session(conn, :access_token)
    conn = assign(conn, :access_token, access_token)
    case get_session(conn, :current_user_id) do
      nil ->
        assign(conn, :current_user, nil)
      id ->
        user = Serge.Repo.get(Serge.User, id)
        assign(conn, :current_user, user)
    end
  end
end
