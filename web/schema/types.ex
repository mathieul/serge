defmodule Serge.Schema.Types do
  use Absinthe.Schema.Notation

  object :user do
    field :id, :id
    field :uid, :string
    field :name, :string
    field :email, :string
    field :avatar_url, :string
  end

  scalar :time do
    description "ISOz time",
    parse &Timex.parse(&1, "{ISOz}")
    serialize &Timex.format!(&1, "{ISOz}")
  end
end
