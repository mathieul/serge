defmodule Serge.Router do
  use Serge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Serge do
    pipe_through :browser

    get "/", HomeController, :index
    resources "/users", UserController, only: [:new, :create, :show]
  end
end
