defmodule Tempo.HealthData do
  @moduledoc """
  The HealthData context.
  """

  import Ecto.Query, warn: false
  alias Tempo.Repo

  alias Tempo.HealthData.Sample
  alias Tempo.HealthData.SampleCounter

  @doc """
  Returns a paginated list of samples with optional type filter.

  ## Options
    * `:page` - Page number (default: 1)
    * `:per_page` - Items per page (default: 20)
    * `:type` - Filter by sample type (optional)

  ## Examples

      iex> list_samples(page: 1, per_page: 20)
      %{samples: [%Sample{}, ...], page: 1, per_page: 20, has_more: true}

  """
  def list_samples(opts \\ []) do
    page = Keyword.get(opts, :page, 1)
    per_page = Keyword.get(opts, :per_page, 20)
    type_filter = Keyword.get(opts, :type)

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

    %{
      samples: samples,
      page: page,
      per_page: per_page,
      has_more: has_more
    }
  end

  @doc """
  Returns a list of unique sample types.
  NOTE: Types are Apple Health keys.

  Uses ETS cache from SampleCounter for fast lookups.

  ## Examples

      iex> list_sample_types()
      ["HKQuantityTypeIdentifierBodyMass", "HKQuantityTypeIdentifierStepCount", ...]

  """
  def list_sample_types do
    # Get types from ETS cache (much faster than DB query)
    SampleCounter.get_all()
    |> Map.keys()
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
