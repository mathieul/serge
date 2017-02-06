defmodule Serge.HomeController do
  use Serge.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def authenticated(conn, _params) do
    render conn, "authenticated.html", elm_module: "Main", elm_app_config: %{}
  end
end
