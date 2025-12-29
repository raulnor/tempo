defmodule TempoWeb.HealthController do
  use TempoWeb, :controller
  alias Tempo.HealthData.Sample
  alias Tempo.Repo

  def sync(conn, %{"_json" => samples}) when is_list(samples) do
    {stored, failed} =
      samples
      |> Enum.map(&parse_and_store/1)
      |> Enum.split_with(fn result -> result == :ok end)

    json(conn, %{
      received: length(samples),
      stored: length(stored),
      failed: length(failed)
    })
  end

  defp parse_and_store(%{
    "uuid" => uuid,
    "type" => type,
    "quantity" => quantity,
    "startDate" => start_date,
    "endDate" => end_date
  }) do
    attrs = %{
      uuid: uuid,
      type: type,
      quantity: quantity,
      start_date: parse_datetime(start_date),
      end_date: parse_datetime(end_date)
    }

    %Sample{}
    |> Sample.changeset(attrs)
    |> Repo.insert(
        on_conflict: :replace_all,
        conflict_target: :uuid
      )
    |> case do
      {:ok, _} -> :ok
      {:error, _changeset} -> :error
    end
  rescue
    _ -> :error
  end

  defp parse_datetime(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, datetime, _offset} -> datetime
      _ -> nil
    end
  end
  defp parse_datetime(_), do: nil
end
