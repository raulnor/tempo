defmodule Tempo.HealthData.SampleCounter do
  @moduledoc """
  GenServer that maintains an ETS table for tracking per-sample-type counts.

  The ETS table stores counts for each sample type, allowing for fast
  in-memory lookups without querying the database.
  """
  use GenServer
  require Logger

  @table_name :sample_counts

  # Client API

  @doc """
  Starts the SampleCounter GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Increments the count for a given sample type.

  ## Examples

      iex> SampleCounter.increment("HKQuantityTypeIdentifierStepCount")
      :ok
  """
  def increment(sample_type) do
    GenServer.call(__MODULE__, {:increment, sample_type})
  end

  @doc """
  Increments the count for a given sample type by a specific amount.

  ## Examples

      iex> SampleCounter.increment("HKQuantityTypeIdentifierStepCount", 5)
      :ok
  """
  def increment(sample_type, amount) when is_integer(amount) and amount > 0 do
    GenServer.call(__MODULE__, {:increment, sample_type, amount})
  end

  @doc """
  Decrements the count for a given sample type.

  ## Examples

      iex> SampleCounter.decrement("HKQuantityTypeIdentifierStepCount")
      :ok
  """
  def decrement(sample_type) do
    GenServer.call(__MODULE__, {:decrement, sample_type})
  end

  @doc """
  Decrements the count for a given sample type by a specific amount.

  ## Examples

      iex> SampleCounter.decrement("HKQuantityTypeIdentifierStepCount", 3)
      :ok
  """
  def decrement(sample_type, amount) when is_integer(amount) and amount > 0 do
    GenServer.call(__MODULE__, {:decrement, sample_type, amount})
  end

  @doc """
  Gets the current count for a given sample type.

  ## Examples

      iex> SampleCounter.get("HKQuantityTypeIdentifierStepCount")
      42
  """
  def get(sample_type) do
    case :ets.lookup(@table_name, sample_type) do
      [{^sample_type, count}] -> count
      [] -> 0
    end
  end

  @doc """
  Gets all sample type counts as a map.

  ## Examples

      iex> SampleCounter.get_all()
      %{"HKQuantityTypeIdentifierStepCount" => 42, "HKQuantityTypeIdentifierHeartRate" => 100}
  """
  def get_all do
    @table_name
    |> :ets.tab2list()
    |> Map.new()
  end

  @doc """
  Resets the count for a specific sample type to zero.

  ## Examples

      iex> SampleCounter.reset("HKQuantityTypeIdentifierStepCount")
      :ok
  """
  def reset(sample_type) do
    GenServer.call(__MODULE__, {:reset, sample_type})
  end

  @doc """
  Resets all counts to zero.

  ## Examples

      iex> SampleCounter.reset_all()
      :ok
  """
  def reset_all do
    GenServer.call(__MODULE__, :reset_all)
  end

  @doc """
  Syncs the ETS table with the database by counting all samples per type.
  This is useful for initialization or recovery.

  ## Examples

      iex> SampleCounter.sync_from_database()
      :ok
  """
  def sync_from_database do
    GenServer.call(__MODULE__, :sync_from_database, :timer.seconds(30))
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table with public read access for performance
    # Use :set type since we want unique sample types as keys
    # :public allows other processes to read directly without going through GenServer
    table = :ets.new(@table_name, [:set, :public, :named_table, read_concurrency: true])

    Logger.info("SampleCounter started with ETS table: #{@table_name}")

    # Optionally sync from database on startup
    send(self(), :initial_sync)

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:increment, sample_type}, _from, state) do
    :ets.update_counter(@table_name, sample_type, {2, 1}, {sample_type, 0})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:increment, sample_type, amount}, _from, state) do
    :ets.update_counter(@table_name, sample_type, {2, amount}, {sample_type, 0})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:decrement, sample_type}, _from, state) do
    :ets.update_counter(@table_name, sample_type, {2, -1}, {sample_type, 0})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:decrement, sample_type, amount}, _from, state) do
    :ets.update_counter(@table_name, sample_type, {2, -amount}, {sample_type, 0})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:reset, sample_type}, _from, state) do
    :ets.insert(@table_name, {sample_type, 0})
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:reset_all, _from, state) do
    :ets.delete_all_objects(@table_name)
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:sync_from_database, _from, state) do
    case sync_counts_from_db() do
      {:ok, count} ->
        Logger.info("Synced #{count} sample types from database to ETS")
        {:reply, :ok, state}

      {:error, reason} ->
        Logger.error("Failed to sync from database: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_info(:initial_sync, state) do
    case sync_counts_from_db() do
      {:ok, count} ->
        Logger.info("Initial sync complete: #{count} sample types loaded")

      {:error, reason} ->
        Logger.warning("Initial sync failed: #{inspect(reason)}")
    end

    {:noreply, state}
  end

  # Private Functions

  defp sync_counts_from_db do
    import Ecto.Query

    try do
      # Query to get count per sample type
      query =
        from s in Tempo.HealthData.Sample,
          group_by: s.type,
          select: {s.type, count(s.uuid)}

      results = Tempo.Repo.all(query)

      # Clear existing data and insert new counts
      :ets.delete_all_objects(@table_name)
      :ets.insert(@table_name, results)

      {:ok, length(results)}
    rescue
      e ->
        {:error, e}
    end
  end
end
