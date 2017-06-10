defmodule Serge.Web.Api.StoryController do
  use Serge.Web, :controller

  def index(conn, params) do
    json conn, %{params: params, assigns: conn.assigns}
  end
end
