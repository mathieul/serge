defmodule Serge.Web.Controllers.Helpers do
  import Phoenix.Controller, only: [put_layout: 2]

  def set_authenticated_layout(conn, _options) do
    put_layout(conn, "authenticated.html")
  end
end
