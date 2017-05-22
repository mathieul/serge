defmodule Serge.Web.Schema.Helpers do
  import Ecto.Query

  def by_id(schema, ids) do
    schema
    |> where([s], s.id in ^ids)
    |> Serge.Repo.all()
    |> Map.new(&{&1.id, &1})
  end
end
