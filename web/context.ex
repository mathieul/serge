defmodule Serge.Context do
  import Plug.Conn

  @moduledoc """
  This module is just a regular plug that can look at the conn struct and build
  the appropriate absinthe context.
  """

  @behaviour Plug

  def init(opts), do: opts
  def call(conn, _) do
    context = %{current_user: conn.assigns.current_user}
    conn
    |> put_private(:absinthe, %{context: context})
  end
end
