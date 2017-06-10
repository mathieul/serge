defmodule Serge.Web.HomeController do
  use Serge.Web, :controller

  plug :shows_navigation_top_bar when action in [:tasker]

  def index(conn, _params) do
    if conn.assigns.current_user do
      conn
      |> put_session(:return_to, nil)
      |> redirect(external: get_session(conn, :return_to) || tasker_path(conn, :tasker))
    else
      render(conn, "index.html", activities: Activity.recent_activity)
    end
  end

  def tasker(conn, _params) do
    config = elm_app_config(conn.assigns.current_user, conn.assigns.access_token)
    render(conn, "tasker.html", elm_module: "Tasker", elm_app_config: config)
  end

  defp elm_app_config(nil, _), do: %{}
  defp elm_app_config(current_user, access_token) do
    %{
      "id"           => current_user.id,
      "name"         => current_user.name,
      "email"        => current_user.email,
      "access_token" => access_token
    }
  end
end
