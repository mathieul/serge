defmodule Serge.HomeController do
  use Serge.Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
