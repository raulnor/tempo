defmodule Tempo.HealthData.Aggregations do
  @moduledoc """
  Functions for aggregating health data samples for charting and analysis.
  """

  import Ecto.Query
  alias Tempo.Repo
  alias Tempo.HealthData.Sample

  @doc """
  Get daily aggregated data for a specific metric type over the last N days.
  Returns a list of {date, value} tuples.
  """
  def daily_aggregates(type, days \\ 30) do
    start_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    query =
      from s in Sample,
        where: s.type == ^type and s.start_date >= ^start_date,
        select: %{
          date: fragment("date(?)", s.start_date),
          total: sum(s.quantity),
          avg: avg(s.quantity),
          count: count(s.uuid)
        },
        group_by: fragment("date(?)", s.start_date),
        order_by: fragment("date(?)", s.start_date)

    Repo.all(query)
    |> Enum.map(fn row ->
      %{
        date: row.date |> to_string(),
        total: row.total |> decimal_to_float(),
        avg: row.avg |> decimal_to_float(),
        count: row.count
      }
    end)
  end

  @doc """
  Get time series data for charting. Returns dates and values separately.
  Fills in missing dates with nil values.
  """
  def time_series(type, days \\ 30) do
    aggregates = daily_aggregates(type, days)

    # Create a map of date -> value
    data_map =
      aggregates
      |> Enum.map(fn %{date: date, total: total} -> {date, total} end)
      |> Map.new()

    # Generate all dates in range
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -days)

    dates =
      Date.range(start_date, end_date)
      |> Enum.map(&Date.to_string/1)

    values =
      dates
      |> Enum.map(fn date -> Map.get(data_map, date, 0) end)

    {dates, values}
  end

  @doc """
  Get statistics for a metric type over a time period.
  """
  def stats(type, days \\ 30) do
    start_date = DateTime.utc_now() |> DateTime.add(-days, :day)

    query =
      from s in Sample,
        where: s.type == ^type and s.start_date >= ^start_date,
        select: %{
          total: sum(s.quantity),
          avg: avg(s.quantity),
          min: min(s.quantity),
          max: max(s.quantity),
          count: count(s.uuid)
        }

    case Repo.one(query) do
      nil ->
        %{total: 0, avg: 0, min: 0, max: 0, count: 0}

      stats ->
        %{
          total: stats.total |> decimal_to_float(),
          avg: stats.avg |> decimal_to_float(),
          min: stats.min || 0,
          max: stats.max || 0,
          count: stats.count
        }
    end
  end

  @doc """
  Compare two metric types side by side over time.
  """
  def compare_metrics(type1, type2, days \\ 30) do
    {dates, values1} = time_series(type1, days)
    {_dates, values2} = time_series(type2, days)

    %{
      dates: dates,
      series: [
        %{name: type1, values: values1},
        %{name: type2, values: values2}
      ]
    }
  end


  # Helper to convert Decimal to float
  defp decimal_to_float(nil), do: 0.0
  defp decimal_to_float(value) when is_float(value), do: value
  defp decimal_to_float(value) when is_integer(value), do: value * 1.0
  defp decimal_to_float(%Decimal{} = value), do: Decimal.to_float(value)
  defp decimal_to_float(value), do: value
end
