defmodule Serge.Web.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use Serge.Web, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> render(Serge.Web.ChangesetView, "error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> render(Serge.Web.ErrorView, :"404")
  end

  def call(conn, {:error, :not_authorized}) do
    conn
    |> put_status(:unauthorized)
    |> render(Serge.Web.ErrorView, :"401")
  end
end
