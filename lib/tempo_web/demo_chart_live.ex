defmodule TempoWeb.DemoChartLive do
  use TempoWeb, :live_view

  alias Tempo.FakeData
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> assign(:options, %{line_stack: %{cumulative: true}})
     |> assign(:reload_timers, %{})
     |> assign_async_schedule([:line_stack, :gauge_multi_title], fn opts ->
       %{
         line_stack: FakeData.get_line_stack_data(opts[:line_stack][:cumulative]),
         gauge_multi_title: FakeData.get_gauge_multi_title_data()
       }
     end)
     |> assign_async_schedule(:process_gauge, fn _opts ->
       %{process_gauge: FakeData.get_process_count()}
     end)}
  end

  defp assign_async_schedule(socket, key_or_keys, fun, update_in \\ :timer.seconds(5)) do
    keys = List.wrap(key_or_keys)

    options =
      keys
      |> Enum.map(&{&1, %{}})
      |> Enum.into(%{})
      |> Map.merge(socket.assigns.options)

    socket =
      socket
      |> start_async_schedule(key_or_keys, fun, update_in)
      |> assign(:options, options)

    Enum.reduce(keys, socket, fn key, socket ->
      assign(socket, key, AsyncResult.loading())
    end)
  end

  defp start_async_schedule(socket, key_or_keys, fun, update_in) do
    options = Map.take(socket.assigns.options, List.wrap(key_or_keys))

    start_async(socket, key_or_keys, fn ->
      {fun.(options), fun, update_in}
    end)
  end

  @impl true
  def handle_async(key_or_keys, {:ok, {values, fun, update_in}}, socket) do
    socket =
      key_or_keys
      |> List.wrap()
      |> Enum.reduce(socket, fn key, socket ->
        async = Map.fetch!(socket.assigns, key)
        value = Map.fetch!(values, key)

        socket
        |> push_chart_event(key, value)
        |> assign(key, AsyncResult.ok(async, value))
      end)
      |> assign(
        :reload_timers,
        Map.put(
          socket.assigns.reload_timers,
          key_or_keys,
          start_timer(key_or_keys, fun, update_in)
        )
      )

    {:noreply, socket}
  end

  def handle_async(key_or_keys, {:exit, reason}, socket) do
    socket =
      key_or_keys
      |> List.wrap()
      |> Enum.reduce(socket, fn key, socket ->
        async = Map.fetch!(socket.assigns, key)

        assign(socket, key, AsyncResult.failed(async, reason))
      end)

    {:noreply, socket}
  end

  defp start_timer(key_or_keys, fun, update_in, send_after \\ nil) do
    ref =
      Process.send_after(self(), {:async, key_or_keys, fun, update_in}, send_after || update_in)

    {ref, {fun, update_in}}
  end

  @impl true
  def handle_info({:async, key_or_keys, fun, update_in}, socket) do
    socket = start_async_schedule(socket, key_or_keys, fun, update_in)

    {:noreply, socket}
  end

  @impl true
  def handle_event("options", %{"name" => "line_stack", "cumulative" => cumulative}, socket) do
    key_or_keys = [:line_stack, :gauge_multi_title]
    key_options = Map.put(socket.assigns.options[:line_stack], :cumulative, cumulative == "true")
    {timer, {fun, update_in}} = Map.fetch!(socket.assigns.reload_timers, key_or_keys)

    Process.cancel_timer(timer)

    socket =
      socket
      |> assign(:options, Map.put(socket.assigns.options, :line_stack, key_options))
      |> assign(
        :reload_timers,
        Map.put(
          socket.assigns.reload_timers,
          key_or_keys,
          start_timer(key_or_keys, fun, update_in, 1)
        )
      )

    {:noreply, socket}
  end

  defp push_chart_event(socket, :line_stack, {columns, data}) do
    option =
      %{
        tooltip: %{
          trigger: "axis"
        },
        legend: %{
          data: Enum.map(data, & &1.name),
          selected: %{"Email" => false}
        },
        grid: %{
          left: "3%",
          right: "4%",
          bottom: "3%",
          containLabel: true
        },
        toolbox: %{
          feature: %{
            saveAsImage: %{}
          }
        },
        xAxis: %{
          type: "category",
          boundaryGap: false,
          data: columns
        },
        yAxis: %{
          type: "value"
        },
        series:
          Enum.map(
            data,
            &%{
              name: &1.name,
              type: "line",
              stack: "Total",
              data: &1.values
            }
          )
      }

    push_event(socket, "chart-option-line_stack", option)
  end

  defp push_chart_event(socket, :gauge_multi_title, data) do
    option = %{
      series: [
        %{
          type: "gauge",
          anchor: %{
            show: true,
            showAbove: true,
            size: 18,
            itemStyle: %{
              color: "#FAC858"
            }
          },
          pointer: %{
            icon:
              "path://M2.9,0.7L2.9,0.7c1.4,0,2.6,1.2,2.6,2.6v115c0,1.4-1.2,2.6-2.6,2.6l0,0c-1.4,0-2.6-1.2-2.6-2.6V3.3C0.3,1.9,1.4,0.7,2.9,0.7z",
            width: 8,
            length: "80%",
            offsetCenter: [0, "8%"]
          },
          progress: %{
            show: true,
            overlap: true,
            roundCap: true
          },
          axisLine: %{
            roundCap: true
          },
          data: [
            %{
              value: data.good,
              name: "Good",
              title: %{
                offsetCenter: ["-40%", "80%"],
                fontSize: 10
              },
              detail: %{
                offsetCenter: ["-40%", "95%"],
                fontSize: 10,
                height: 10,
                width: 20
              }
            },
            %{
              value: data.better,
              name: "Better",
              title: %{
                offsetCenter: ["0%", "80%"],
                fontSize: 10
              },
              detail: %{
                offsetCenter: ["0%", "95%"],
                fontSize: 10,
                height: 10,
                width: 20
              }
            },
            %{
              value: data.perfect,
              name: "Perfect",
              title: %{
                offsetCenter: ["40%", "80%"],
                fontSize: 10
              },
              detail: %{
                offsetCenter: ["40%", "95%"],
                fontSize: 10,
                height: 10,
                width: 20
              }
            }
          ],
          title: %{
            fontSize: 14
          },
          detail: %{
            width: 40,
            height: 14,
            fontSize: 14,
            color: "#fff",
            backgroundColor: "inherit",
            borderRadius: 3,
            formatter: "{value}%"
          }
        }
      ]
    }

    push_event(socket, "chart-option-guage_multi_title", option)
  end

  defp push_chart_event(socket, :process_gauge, data) do
    option = %{
      series: [
        %{
          name: "Processes",
          type: "gauge",
          data: [
            %{
              value: data
            }
          ]
        }
      ]
    }

    push_event(socket, "chart-option-process_gauge", option)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="w-full grid grid-row gap-4">
        <div class="w-full grid grid-row gap-4 p-4">
          <.header>
            Line stack
            <:subtitle>
              <.button
                :if={@options[:line_stack][:cumulative]}
                phx-click="options"
                phx-value-name={:line_stack}
                phx-value-cumulative="false"
              >
                Single
              </.button>
              <.button
                :if={@options[:line_stack][:cumulative] != true}
                phx-click="options"
                phx-value-name={:line_stack}
                phx-value-cumulative="true"
              >
                Rolling
              </.button>
            </:subtitle>
          </.header>

          <.async_result assign={@line_stack}>
            <:loading>Loading...</:loading>
            <:failed>
              <error>Failed to load chart</error>
            </:failed>
          </.async_result>

          <div id="line_stack" phx-hook="Chart" class="w-full h-[20rem]" phx-update="ignore" />
        </div>

        <div class="grid w-full grid-cols-1 gap-4 xl:grid-cols-2">
          <div class="grid grid-row gap-4 p-4">
            <.header>
              Gauge multi title
            </.header>

            <.async_result assign={@gauge_multi_title}>
              <:loading>Loading..</:loading>
              <:failed>
                <error>Failed to load chart</error>
              </:failed>
            </.async_result>

            <div id="guage_multi_title" phx-hook="Chart" class="w-full h-[20rem]" phx-update="ignore" />
          </div>

          <div class="grid grid-row gap-4 p-4">
            <.header>
              Processes
            </.header>

            <.async_result assign={@process_gauge}>
              <:loading>Loading...</:loading>
              <:failed>
                <error>Failed to load chart</error>
              </:failed>
            </.async_result>

            <div id="process_gauge" phx-hook="Chart" class="w-full h-[20rem]" phx-update="ignore" />
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
