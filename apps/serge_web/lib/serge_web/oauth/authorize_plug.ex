defmodule Serge.Web.Oauth.AuthorizePlug do
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2, current_url: 1]

  def init(options), do: options

  def call(conn, _options) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:warning, "You must authenticate to access this page")
      |> put_session(:return_to, current_url(conn))
      |> redirect(to: "/")
      |> halt
    end
  end

end
