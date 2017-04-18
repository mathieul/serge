defmodule Serge.Web.Schema.CommonTypes do
  use Absinthe.Schema.Notation

  scalar :time do
    description "ISOz time"
    parse &Timex.parse(&1, "{ISOz}")
    serialize &Timex.format!(&1, "{ISOz}")
  end

  scalar :date do
    description "ISO8601 date"
    parse &Ecto.Date.cast!/1
    serialize &Ecto.Date.to_iso8601/1
  end
end
