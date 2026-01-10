defmodule TempoWeb.MetricsLive do
  use TempoWeb, :live_view
  alias Tempo.HealthData
  alias Tempo.HealthData.{Aggregations, Formatter}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:selected_metric, nil)
      |> assign(:metric_types, [])
      |> assign(:time_range, 30)
      |> assign(:loading, true)
      |> assign(:stats, nil)

    if connected?(socket) do
      send(self(), :load_data)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info(:load_data, socket) do
    metric_types = HealthData.list_sample_types()

    # Select first metric by default if available
    selected_metric = List.first(metric_types)

    socket =
      socket
      |> assign(:metric_types, metric_types)
      |> assign(:selected_metric, selected_metric)
      |> assign(:loading, false)

    socket =
      if selected_metric do
        update_charts(socket, selected_metric, socket.assigns.time_range)
      else
        socket
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_metric", %{"metric_form" => %{"metric" => metric}}, socket) do
    socket =
      socket
      |> assign(:selected_metric, metric)
      |> update_charts(metric, socket.assigns.time_range)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change_time_range", %{"time_range_form" => %{"range" => range}}, socket) do
    time_range = String.to_integer(range)

    socket =
      socket
      |> assign(:time_range, time_range)
      |> update_charts(socket.assigns.selected_metric, time_range)

    {:noreply, socket}
  end

  defp update_charts(socket, nil, _time_range), do: socket

  defp update_charts(socket, metric, time_range) do
    # Get data
    {dates, values} = Aggregations.time_series(metric, time_range)
    stats = Aggregations.stats(metric, time_range)

    # Update stats and push chart events
    socket
    |> assign(:stats, stats)
    |> push_time_series_chart(dates, values, metric)
  end

  defp push_time_series_chart(socket, dates, values, metric) do
    human_name = Formatter.humanize(metric)

    option = %{
      title: %{
        text: "#{human_name} Over Time",
        left: "center"
      },
      tooltip: %{
        trigger: "axis",
        axisPointer: %{
          type: "cross"
        }
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        containLabel: true
      },
      xAxis: %{
        type: "category",
        data: dates,
        boundaryGap: true
      },
      yAxis: %{
        type: "value"
      },
      series: [
        %{
          name: human_name,
          type: "bar",
          data: values,
          itemStyle: %{
            color: "#3b82f6"
          }
        }
      ]
    }

    push_event(socket, "chart-option-time_series_chart", option)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="container mx-auto px-4 py-8">
        <%= if @loading do %>
          <div class="flex justify-center items-center h-64">
            <span class="loading loading-spinner loading-lg"></span>
          </div>
        <% else %>
          <%= if Enum.empty?(@metric_types) do %>
            <div class="alert alert-info">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                class="stroke-current shrink-0 w-6 h-6"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                >
                </path>
              </svg>
              <span>No health data available yet. Sync data from your iPhone to get started.</span>
            </div>
          <% else %>
            <!-- Metric Selector and Time Range -->
            <div class="flex flex-wrap gap-4 mb-8">
              <div class="form-control w-full max-w-xs">
                <label class="label">
                  <span class="label-text">Select Metric</span>
                </label>
                <form phx-change="select_metric">
                  <select class="select select-bordered" name="metric_form[metric]">
                    <%= for metric <- @metric_types do %>
                      <option value={metric} selected={metric == @selected_metric}>
                        {Formatter.humanize(metric)}
                      </option>
                    <% end %>
                  </select>
                </form>
              </div>

              <div class="form-control w-full max-w-xs">
                <label class="label">
                  <span class="label-text">Time Range</span>
                </label>
                <form phx-change="change_time_range">
                  <select class="select select-bordered" name="time_range_form[range]">
                    <option value="7" selected={@time_range == 7}>Last 7 days</option>
                    <option value="30" selected={@time_range == 30}>Last 30 days</option>
                    <option value="90" selected={@time_range == 90}>Last 90 days</option>
                    <option value="180" selected={@time_range == 180}>Last 6 months</option>
                    <option value="365" selected={@time_range == 365}>Last year</option>
                  </select>
                </form>
              </div>
            </div>
            
    <!-- Statistics Cards -->
            <%= if @stats do %>
              <div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-8">
                <div class="stat bg-base-200 rounded-lg">
                  <div class="stat-title">Total</div>
                  <div class="stat-value text-2xl">{format_stat(@stats.total)}</div>
                  <div class="stat-desc">Sum of all values</div>
                </div>
                <div class="stat bg-base-200 rounded-lg">
                  <div class="stat-title">Average</div>
                  <div class="stat-value text-2xl">{format_stat(@stats.avg)}</div>
                  <div class="stat-desc">Mean value</div>
                </div>
                <div class="stat bg-base-200 rounded-lg">
                  <div class="stat-title">Minimum</div>
                  <div class="stat-value text-2xl">{format_stat(@stats.min)}</div>
                  <div class="stat-desc">Lowest recorded</div>
                </div>
                <div class="stat bg-base-200 rounded-lg">
                  <div class="stat-title">Maximum</div>
                  <div class="stat-value text-2xl">{format_stat(@stats.max)}</div>
                  <div class="stat-desc">Highest recorded</div>
                </div>
                <div class="stat bg-base-200 rounded-lg">
                  <div class="stat-title">Samples</div>
                  <div class="stat-value text-2xl">{@stats.count}</div>
                  <div class="stat-desc">Total data points</div>
                </div>
              </div>
            <% end %>
            
    <!-- Chart -->
            <div class="card bg-base-200">
              <div class="card-body">
                <div id="time_series_chart" phx-hook="Chart" class="w-full h-96" phx-update="ignore">
                </div>
              </div>
            </div>
          <% end %>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp format_stat(value) when is_float(value), do: Float.round(value, 1)
  defp format_stat(value), do: value
end
