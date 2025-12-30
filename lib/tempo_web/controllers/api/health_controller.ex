defmodule TempoWeb.HealthController do
  use TempoWeb, :controller
  alias Tempo.HealthData.Sample
  alias Tempo.Repo

  def sync(conn, %{"_json" => samples}) when is_list(samples) do
    parsed_samples =
      samples
      |> Enum.map(&parse_sample/1)
      |> Enum.reject(&is_nil/1)

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries = Enum.map(parsed_samples, fn attrs ->
      Map.merge(attrs, %{inserted_at: now, updated_at: now})
    end)

    {inserted, _} = Repo.insert_all(
      Sample,
      entries,
      on_conflict: :replace_all,
      conflict_target: :uuid
    )

    json(conn, %{
      received: length(samples),
      stored: inserted,
      failed: length(samples) - length(parsed_samples)
    })
  end

  defp parse_sample(%{
    "uuid" => uuid,
    "type" => type,
    "quantity" => quantity,
    "startDate" => start_date,
    "endDate" => end_date
  }) do
    %{
      uuid: uuid,
      type: type,
      quantity: to_float(quantity),
      start_date: parse_datetime(start_date),
      end_date: parse_datetime(end_date)
    }
  rescue
    _ -> nil
  end
  defp parse_sample(_), do: nil

  defp to_float(value) when is_float(value), do: value
  defp to_float(value) when is_integer(value), do: value * 1.0
  defp to_float(value) when is_binary(value), do: String.to_float(value)
  defp to_float(_), do: 0.0

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end
  defp parse_datetime(_), do: nil
end
