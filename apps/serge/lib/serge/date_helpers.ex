defmodule Serge.DateHelpers do
  import Ecto.Date, only: [cast!: 1, cast: 1]
  import Ecto.Changeset, only: [validate_change: 3]

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

  def validate_date(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, value ->
      case cast(value) do
        {:ok, _} ->
          []
        :error ->
          [{field, options[:message] || "is not a valid date"}]
      end
    end)
  end
end
