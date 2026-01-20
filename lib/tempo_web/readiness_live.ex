defmodule TempoWeb.ReadinessLive do
  use TempoWeb, :live_view
  import Ecto.Query, warn: false
  alias Tempo.Repo
  alias Tempo.HealthData.Sample

  @hrv_type "HKQuantityTypeIdentifierHeartRateVariabilitySDNN"

  @impl true
  def mount(_params, _session, socket) do
    hrv_data = get_hrv_data()
    readiness_status = calculate_readiness(hrv_data)

    socket =
      socket
      |> assign(:page_title, "HRV Readiness")
      |> assign(:hrv_data, hrv_data)
      |> assign(:readiness_status, readiness_status)
      |> assign(:tooltip, nil)
      |> assign(:show_info, false)

    {:ok, socket}
  end

  @impl true
  def handle_event("show_tooltip", %{"index" => index}, socket) do
    index = String.to_integer(index)
    hrv_data = socket.assigns.hrv_data

    tooltip =
      if index >= 0 and index < length(hrv_data) do
        point = Enum.at(hrv_data, index)

        # Calculate readiness for this specific point
        readiness = calculate_point_readiness(point, hrv_data, index)

        %{
          date: format_date(point.date),
          value: Float.round(point.value, 1),
          rolling_avg: if(point.rolling_avg, do: Float.round(point.rolling_avg, 1), else: nil),
          index: index,
          readiness: readiness
        }
      else
        nil
      end

    {:noreply, assign(socket, :tooltip, tooltip)}
  end

  @impl true
  def handle_event("hide_tooltip", _params, socket) do
    {:noreply, assign(socket, :tooltip, nil)}
  end

  @impl true
  def handle_event("toggle_info", _params, socket) do
    {:noreply, assign(socket, :show_info, !socket.assigns.show_info)}
  end

  # Get HRV data for the last 7 days (morning readings only)
  defp get_hrv_data do
    # Get data for last 37 days (to calculate 30-day std dev for oldest day)
    query =
      from s in Sample,
        where: s.type == ^@hrv_type,
        where:
          fragment(
            "time(start_date) >= ? AND time(start_date) <= ?",
            "04:00:00",
            "14:00:00"
          ),
        where: s.start_date >= ago(37, "day"),
        order_by: [asc: s.start_date],
        select: %{
          date: fragment("date(start_date, '-5 hours')"),
          value: s.quantity,
          start_date: s.start_date
        }

    raw_data = Repo.all(query)

    # Group by date and take first reading per day
    daily_readings =
      raw_data
      |> Enum.group_by(& &1.date)
      |> Enum.map(fn {date, readings} ->
        first_reading = Enum.min_by(readings, & &1.start_date)
        {Date.from_iso8601!(date), first_reading.value}
      end)
      |> Enum.sort_by(fn {date, _} -> date end, Date)

    # Calculate rolling averages
    daily_readings
    |> Enum.with_index()
    |> Enum.map(fn {{date, value}, index} ->
      # Get 7-day rolling average (including current day)
      rolling_avg =
        if index >= 6 do
          values =
            daily_readings
            |> Enum.slice(max(0, index - 6), 7)
            |> Enum.map(fn {_, v} -> v end)

          Enum.sum(values) / length(values)
        else
          nil
        end

      %{date: date, value: value, rolling_avg: rolling_avg}
    end)
    |> Enum.take(-7)
  end

  # Calculate readiness for a specific point
  defp calculate_point_readiness(point, _hrv_data, _index) do
    # If no rolling average, can't calculate
    if point.rolling_avg == nil do
      nil
    else
      # Get 30 days of historical data for std dev calculation
      query =
        from s in Sample,
          where: s.type == ^@hrv_type,
          where:
            fragment(
              "time(start_date) >= ? AND time(start_date) <= ?",
              "04:00:00",
              "14:00:00"
            ),
          where: s.start_date >= ago(30, "day"),
          select: s.quantity

      values = Repo.all(query)

      if length(values) < 7 do
        nil
      else
        std_dev = calculate_std_dev(values)
        value = point.value
        rolling_avg = point.rolling_avg

        cond do
          value > rolling_avg + std_dev ->
            %{status: :go_hard, message: "Go hard", color: "success"}

          value < rolling_avg - std_dev ->
            %{status: :recovery, message: "Recovery", color: "error"}

          true ->
            %{status: :normal, message: "Normal", color: "warning"}
        end
      end
    end
  end

  # Calculate readiness status based on today's HRV vs 7-day avg and 30-day std dev
  defp calculate_readiness([]), do: nil

  defp calculate_readiness(hrv_data) do
    today = List.last(hrv_data)

    # Need at least 7 days for rolling average
    if today.rolling_avg == nil do
      %{status: :insufficient_data, message: "Need at least 7 days of data"}
    else
      # Get 30 days of historical data for std dev calculation
      query =
        from s in Sample,
          where: s.type == ^@hrv_type,
          where:
            fragment(
              "time(start_date) >= ? AND time(start_date) <= ?",
              "04:00:00",
              "14:00:00"
            ),
          where: s.start_date >= ago(30, "day"),
          select: s.quantity

      values = Repo.all(query)

      if length(values) < 7 do
        %{status: :insufficient_data, message: "Need at least 7 days of data"}
      else
        std_dev = calculate_std_dev(values)
        today_value = today.value
        rolling_avg = today.rolling_avg

        cond do
          today_value > rolling_avg + std_dev ->
            %{
              status: :go_hard,
              message: "Go hard",
              color: "success",
              today: today_value,
              avg: rolling_avg,
              std_dev: std_dev
            }

          today_value < rolling_avg - std_dev ->
            %{
              status: :recovery,
              message: "Recovery",
              color: "error",
              today: today_value,
              avg: rolling_avg,
              std_dev: std_dev
            }

          true ->
            %{
              status: :normal,
              message: "Normal",
              color: "warning",
              today: today_value,
              avg: rolling_avg,
              std_dev: std_dev
            }
        end
      end
    end
  end

  defp calculate_std_dev([]), do: 0
  defp calculate_std_dev([_]), do: 0

  defp calculate_std_dev(values) do
    mean = Enum.sum(values) / length(values)

    variance =
      values
      |> Enum.map(fn x -> :math.pow(x - mean, 2) end)
      |> Enum.sum()
      |> Kernel./(length(values))

    :math.sqrt(variance)
  end

  defp format_date(date) do
    Calendar.strftime(date, "%b %d")
  end

  # Generate SVG chart
  defp render_chart(assigns) do
    ~H"""
    <svg
      viewBox="0 0 800 300"
      class="w-full h-auto"
      xmlns="http://www.w3.org/2000/svg"
      id="hrv-chart"
      phx-hook="HRVChart"
    >
      <!-- Chart background -->
      <rect x="0" y="0" width="800" height="300" fill="transparent" />

      <%= if length(@hrv_data) > 0 do %>
        <% # Calculate chart dimensions
        padding = 50
        chart_width = 800 - padding * 2
        chart_height = 300 - padding * 2

        # Find min/max values for scaling
        all_values = Enum.map(@hrv_data, & &1.value)
        all_avg_values = Enum.map(@hrv_data, & &1.rolling_avg) |> Enum.reject(&is_nil/1)
        all_chart_values = all_values ++ all_avg_values

        min_value = Enum.min(all_chart_values) * 0.9
        max_value = Enum.max(all_chart_values) * 1.1
        value_range = max_value - min_value

        # Calculate point positions
        point_spacing = chart_width / max(length(@hrv_data) - 1, 1)

        points =
          @hrv_data
          |> Enum.with_index()
          |> Enum.map(fn {data, index} ->
            x = padding + index * point_spacing
            y = padding + chart_height - (data.value - min_value) / value_range * chart_height
            {x, y, data.value, data.rolling_avg, index}
          end)

        # Calculate rolling average line points
        avg_points =
          points
          |> Enum.filter(fn {_, _, _, avg, _} -> avg != nil end)
          |> Enum.map(fn {x, _, _, avg, _} ->
            y = padding + chart_height - (avg - min_value) / value_range * chart_height
            {x, y}
          end)

        avg_path =
          avg_points
          |> Enum.map(fn {x, y} -> "#{x},#{y}" end)
          |> Enum.join(" L ")
          |> then(fn path -> if path != "", do: "M " <> path, else: "" end) %>
        <!-- Grid lines -->
        <%= for i <- 0..4 do %>
          <% y = padding + i * chart_height / 4 %>
          <line
            x1={padding}
            y1={y}
            x2={800 - padding}
            y2={y}
            stroke="currentColor"
            stroke-opacity="0.1"
            stroke-width="1"
          />
          <% value = max_value - i * value_range / 4 %>
          <text x={padding - 10} y={y + 5} text-anchor="end" class="text-xs fill-current opacity-60">
            {Float.round(value, 0)}
          </text>
        <% end %>
        <!-- X-axis labels -->
        <%= for {data, index} <- Enum.with_index(@hrv_data) do %>
          <% x = padding + index * point_spacing %>
          <text
            x={x}
            y={300 - padding + 20}
            text-anchor="middle"
            class="text-xs fill-current opacity-60"
          >
            {format_date(data.date)}
          </text>
        <% end %>
        <!-- Rolling average line -->
        <%= if avg_path != "" do %>
          <path
            d={avg_path}
            fill="none"
            stroke="#94a3b8"
            stroke-width="2"
            stroke-dasharray="4,4"
            opacity="0.6"
          />
        <% end %>
        <!-- HRV value points -->
        <%= for {x, y, _value, _avg, index} <- points do %>
          <g data-index={index} class="cursor-pointer hrv-point">
            <circle
              cx={x}
              cy={y}
              r="6"
              fill="#3b82f6"
              stroke="white"
              stroke-width="2"
              class="transition-all"
            />
            <%!-- Invisible larger hit area for easier hovering --%>
            <circle cx={x} cy={y} r="15" fill="transparent" />
          </g>
        <% end %>
      <% else %>
        <text x="400" y="200" text-anchor="middle" class="text-base fill-current opacity-60">
          No HRV data available
        </text>
      <% end %>
    </svg>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <%= if @readiness_status do %>
        <%= if @readiness_status.status == :insufficient_data do %>
          <.header>
            Morning HRV Readiness
            <:subtitle>
              {@readiness_status.message}
            </:subtitle>
          </.header>
        <% else %>
          <.header>
            <div class="flex items-center gap-2">
              Morning HRV Readiness
              <button
                type="button"
                phx-click="toggle_info"
                class="btn btn-circle btn-ghost btn-xs"
                title="How it works"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke-width="1.5"
                  stroke="currentColor"
                  class="w-5 h-5"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M9.879 7.519c1.171-1.025 3.071-1.025 4.242 0 1.172 1.025 1.172 2.687 0 3.712-.203.179-.43.326-.67.442-.745.361-1.45.999-1.45 1.827v.75M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9 5.25h.008v.008H12v-.008z"
                  />
                </svg>
              </button>
            </div>
            <:subtitle>
              <%= if @tooltip && @tooltip.readiness do %>
                <span class={[
                  "badge badge-sm mr-2",
                  @tooltip.readiness.color == "success" && "badge-success",
                  @tooltip.readiness.color == "error" && "badge-error",
                  @tooltip.readiness.color == "warning" && "badge-warning"
                ]}>
                  {@tooltip.readiness.message}
                </span>
                {@tooltip.date}: {@tooltip.value} ms
                <%= if @tooltip.rolling_avg do %>
                  | 7-day avg: {@tooltip.rolling_avg} ms
                <% end %>
              <% else %>
                <span class={[
                  "badge badge-sm mr-2",
                  @readiness_status.color == "success" && "badge-success",
                  @readiness_status.color == "error" && "badge-error",
                  @readiness_status.color == "warning" && "badge-warning"
                ]}>
                  {@readiness_status.message}
                </span>
                Today: {Float.round(@readiness_status.today, 1)} ms | 7-day avg: {Float.round(
                  @readiness_status.avg,
                  1
                )} ms
              <% end %>
            </:subtitle>
          </.header>
          <!-- Info Card (Collapsible) -->
          <%= if @show_info do %>
            <div class="card bg-base-200">
              <div class="card-body">
                <h4 class="card-title text-base">How it works</h4>
                <ul class="text-sm space-y-1">
                  <li>
                    <strong class="text-success">Go hard:</strong>
                    HRV is significantly above your 7-day average (>1 std dev)
                  </li>
                  <li>
                    <strong class="text-warning">Normal:</strong>
                    HRV is within normal range of your 7-day average
                  </li>
                  <li>
                    <strong class="text-error">Recovery:</strong>
                    HRV is significantly below your 7-day average (>1 std dev)
                  </li>
                </ul>
                <p class="text-xs opacity-70 mt-2">
                  Data shows morning readings (4am-2pm EST) only. Readiness is calculated using your 7-day rolling average and 30-day standard deviation.
                </p>
              </div>
            </div>
          <% end %>
          <!-- Chart -->
          <div class="card bg-base-200">
            <div class="card-body">
              <h3 class="card-title text-lg mb-4">7-Day HRV Trend</h3>
              {render_chart(assigns)}
              <!-- Legend -->
              <div class="flex justify-center gap-6 mt-4 text-sm">
                <div class="flex items-center gap-2">
                  <div class="w-3 h-3 rounded-full bg-blue-500"></div>
                  <span>Daily HRV</span>
                </div>
                <div class="flex items-center gap-2">
                  <div class="w-8 h-0.5 bg-slate-400 opacity-60" style="border-top: 2px dashed;">
                  </div>
                  <span>7-day average</span>
                </div>
              </div>
            </div>
          </div>
        <% end %>
      <% else %>
        <.header>
          Morning HRV Readiness
          <:subtitle>
            No HRV data available yet. Sync data from your iPhone to get started.
          </:subtitle>
        </.header>
      <% end %>
    </Layouts.app>
    """
  end
end
