defmodule Serge.HomeController do
  use Serge.Web, :controller

  def index(conn, _params) do
    config = elm_app_config(conn.assigns.current_user, conn.assigns.access_token)
    render(conn, "index.html", elm_module: "Tasker", elm_app_config: config)
  end

  defp elm_app_config(nil, _), do: %{}
  defp elm_app_config(current_user, access_token) do
    %{
      "id"           => current_user.id,
      "name"         => current_user.name,
      "email"        => current_user.email,
      "access_token" => access_token,
      "today"        => today()
    }
  end

  defp today do
    Timex.local |> Timex.format!("%Y-%m-%d", :strftime)
  end
end
