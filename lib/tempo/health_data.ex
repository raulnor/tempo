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

  ## Examples

      iex> list_samples(page: 1, per_page: 20)
      %{samples: [%Sample{}, ...], total_count: 100, page: 1, per_page: 20}

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

    total_count = Repo.aggregate(query, :count, :uuid)

    samples =
      query
      |> order_by([s], desc: s.start_date)
      |> limit(^per_page)
      |> offset(^((page - 1) * per_page))
      |> Repo.all()

    %{
      samples: samples,
      total_count: total_count,
      page: page,
      per_page: per_page,
      total_pages: ceil(total_count / per_page)
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
    |> order_by([s], s.type)
    |> Repo.all()
  end
end
