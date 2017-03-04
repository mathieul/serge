defmodule Serge.GraphqlCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require running a GraphQL query.
  """

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      import ExUnit.Case

      def run(document, schema, options \\ []) do
        Absinthe.run(document, schema, options)
      end
    end
  end
end
