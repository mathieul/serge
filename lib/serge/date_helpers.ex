defmodule Serge.DateHelpers do
  import Ecto.Date, only: [cast!: 1]

  def days_from_now(days) when is_integer(days) do
    Timex.local
      |> Timex.shift(days: days)
      |> yyyymmdd
      |> cast!
  end

  def days_ago(days), do: days_from_now(-days)
  def today, do: days_from_now(0)
  def yesterday, do: days_from_now(-1)
  def tomorrow, do: days_from_now(1)
  def later, do: days_from_now(30)

  defp yyyymmdd(time) do
    Timex.format!(time, "%Y-%m-%d", :strftime)
  end
end
