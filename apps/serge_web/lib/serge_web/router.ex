defmodule Serge.Web.Router do
  use Serge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :assign_user_and_token
  end

  pipeline :graphql do
    plug :fetch_session
    plug :assign_user_and_token
    plug Serge.Web.Context
  end

  scope "/", Serge.Web do
    pipe_through :browser

    get "/", HomeController, :index
    get "/tasker", HomeController, :tasker, as: :tasker
    resources "/team_invitations", TeamInvitationController, only: [:edit, :update]
    resources "/teams", TeamController do
      get "/scrum", TeamController, :scrum, as: :scrum
    end
    scope "/team_invitations" do
      get "/:id", TeamInvitationController, :edit
      post "/:id/accept", TeamInvitationController, :accept
      post "/:id/reject", TeamInvitationController, :reject
    end

    if Mix.env == :dev do
      forward "/sent_emails", SentEmailViewer.Plug
    end
  end

  scope "/" do
    pipe_through :graphql

    get "/graphiql",    Absinthe.Plug.GraphiQL, schema: Serge.Web.Schema
    post "/graphiql",   Absinthe.Plug.GraphiQL, schema: Serge.Web.Schema
    forward "/graphql", Absinthe.Plug, schema: Serge.Web.Schema
  end

  scope "/auth", Serge.Web do
    pipe_through :browser

    get "/logout", AuthController, :delete
    get "/:provider", AuthController, :index
    get "/:provider/callback", AuthController, :callback
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
        user = Serge.Repo.get(Serge.Authentication.User, id)
        assign(conn, :current_user, user)
    end
  end
end
