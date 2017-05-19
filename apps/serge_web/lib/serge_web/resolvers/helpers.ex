defmodule Serge.Web.Resolvers.Helpers do
  def format_changeset_errors(changeset) do
    evaluated = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    Enum.map(evaluated, fn { attr, message } -> "#{attr} #{message}" end)
  end
end
