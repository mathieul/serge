defmodule Serge.GraphqlCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require running a GraphQL query.
  """

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import ExUnit.Case

      defp run(doc, user_id) do
        Absinthe.run(doc, Serge.Web.Schema, context: %{current_user: %{id: user_id}})
      end
    end
  end
end
