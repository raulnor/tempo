defmodule TempoWeb.MetricsLive do
  use TempoWeb, :live_view
  alias Tempo.HealthData
  alias Tempo.HealthData.{Aggregations, Formatter}

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Health Metrics")
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
        text: human_name,
        left: "3%",
        top: "3%",
        textStyle: %{
          fontSize: 18,
          fontWeight: "600"
        }
      },
      tooltip: %{
        show: false
      },
      grid: %{
        left: "3%",
        right: "4%",
        bottom: "3%",
        top: "15%",
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
            color: "#3b82f6",
            borderRadius: [4, 4, 0, 0]
          },
          emphasis: %{
            itemStyle: %{
              color: "#fbbf24"
            }
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
          <.header>
            Health Metrics
            <:subtitle>
              Visualize and analyze your health data over time
            </:subtitle>
          </.header>

    <!-- Metric Selector and Time Range -->
          <div class="flex gap-4">
            <div class="flex-1 max-w-xs">
              <form phx-change="select_metric">
                <.input
                  type="select"
                  id="metric_selector"
                  name="metric_form[metric]"
                  label="Select Metric"
                  options={Enum.map(@metric_types, &{Formatter.humanize(&1), &1})}
                  value={@selected_metric}
                />
              </form>
            </div>

            <div class="flex-1 max-w-xs">
              <form phx-change="change_time_range">
                <.input
                  type="select"
                  id="time_range_selector"
                  name="time_range_form[range]"
                  label="Time Range"
                  options={[
                    {"Last 7 days", 7},
                    {"Last 30 days", 30},
                    {"Last 90 days", 90},
                    {"Last 6 months", 180},
                    {"Last year", 365}
                  ]}
                  value={@time_range}
                />
              </form>
            </div>
          </div>

    <!-- Chart -->
          <div class="card bg-base-200">
            <div class="card-body">
              <div id="time_series_chart" phx-hook="Chart" class="w-full h-96" phx-update="ignore">
              </div>
            </div>
          </div>

          <%= if @stats do %>
            <div class="text-sm mt-4 flex flex-wrap justify-center gap-y-2">
              <%= unless Formatter.is_percentage_type?(@selected_metric) do %>
                <span class="mx-2">Total: <span class="font-semibold">{Formatter.format_quantity(@stats.total, @selected_metric)}</span></span>
                <span class="opacity-30">|</span>
              <% end %>
              <span class="mx-2">Avg: <span class="font-semibold">{Formatter.format_quantity(@stats.avg, @selected_metric)}</span></span>
              <span class="opacity-30">|</span>
              <span class="mx-2">Min: <span class="font-semibold">{Formatter.format_quantity(@stats.min, @selected_metric)}</span></span>
              <span class="opacity-30">|</span>
              <span class="mx-2">Max: <span class="font-semibold">{Formatter.format_quantity(@stats.max, @selected_metric)}</span></span>
              <span class="opacity-30">|</span>
              <span class="mx-2">Samples: <span class="font-semibold">{@stats.count}</span></span>
            </div>
          <% end %>
        <% end %>
      <% end %>
    </Layouts.app>
    """
  end
end
