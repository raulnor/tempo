defmodule Tempo.HealthData do
  @moduledoc """
  The HealthData context.
  """

  import Ecto.Query, warn: false
  alias Tempo.Repo

  alias Tempo.HealthData.Sample

  @doc """
  Returns a paginated list of samples with optional type filter.

  ## Options
    * `:page` - Page number (default: 1)
    * `:per_page` - Items per page (default: 20)
    * `:type` - Filter by sample type (optional)
    * `:skip_count` - Skip the expensive COUNT query (default: false)

  ## Examples

      iex> list_samples(page: 1, per_page: 20)
      %{samples: [%Sample{}, ...], total_count: 100, page: 1, per_page: 20}

  """
  def list_samples(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    type_filter = Keyword.get(opts, :type)
    skip_count = Keyword.get(opts, :skip_count, false)

    query = Sample

    query =
      if type_filter && type_filter != "" do
        where(query, [s], s.type == ^type_filter)
      else
        query
      end

    # Fetch one extra record to determine if there are more pages
    samples =
      query
      |> order_by([s], desc: s.start_date)
      |> limit(^(per_page + 1))
      |> offset(^((page - 1) * per_page))
      |> Repo.all()

    has_more = length(samples) > per_page
    samples = Enum.take(samples, per_page)

    # Only count if explicitly requested or on first page
    {total_count, total_pages} =
      if skip_count and page > 1 do
        # Estimate based on current page
        {nil, nil}
      else
        count = Repo.aggregate(query, :count, :uuid)
        {count, ceil(count / per_page)}
      end

    start_record = (page - 1) * per_page + 1
    end_record = start_record + length(samples) - 1

    %{
      samples: samples,
      total_count: total_count,
      page: page,
      per_page: per_page,
      start_record: start_record,
      end_record: end_record,
      total_pages: total_pages,
      has_more: has_more
    }
  end

  @doc """
  Returns a list of unique sample types.
  NOTE: Types are Apple Health keys.

  ## Examples

      iex> list_sample_types()
      ["HKQuantityTypeIdentifierBodyMass", "HKQuantityTypeIdentifierStepCount", ...]

  """
  def list_sample_types do
    Sample
    |> select([s], s.type)
    |> distinct(true)
    |> Repo.all()
    |> Enum.sort_by(&Tempo.HealthData.Formatter.humanize/1)
  end

  @doc """
  Returns the most recent sample for each type.

  ## Examples

      iex> list_latest_samples()
      [%Sample{type: "HKQuantityTypeIdentifierBodyMass", ...}, ...]

  """
  def list_latest_samples do
    # Get all sample types
    types = list_sample_types()

    # For each type, get the most recent sample
    Enum.map(types, fn type ->
      Sample
      |> where([s], s.type == ^type)
      |> order_by([s], desc: s.start_date)
      |> limit(1)
      |> Repo.one()
    end)
    |> Enum.reject(&is_nil/1)
  end
end
