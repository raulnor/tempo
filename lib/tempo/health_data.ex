defmodule Tempo.HealthData do
  @moduledoc """
  The HealthData context.
  """

  import Ecto.Query, warn: false
  alias Tempo.Repo

  alias Tempo.HealthData.Sample

  @doc """
  Returns the list of samples.

  ## Examples

      iex> list_samples()
      [%Sample{}, ...]

  """
  def list_samples do
    Sample
    |> limit(100)
    |> Repo.all()
  end

  @doc """
  Gets a single sample.

  Raises if the Sample does not exist.

  ## Examples

      iex> get_sample!(123)
      %Sample{}

  """
  def get_sample!(uuid) do
    Repo.get!(Sample, uuid)
  end
end
