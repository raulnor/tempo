defmodule TempoWeb.SampleLive do
  use TempoWeb, :live_view

  alias Tempo.HealthData
  alias Tempo.HealthData.{Formatter, SampleCounter}

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:sample_types, HealthData.list_sample_types())
     |> assign(:selected_type, nil)
     |> assign(:page, 1)
     |> assign(:page_title, "Health Samples")
     |> assign(:per_page, 20)}
  end

  def handle_params(params, _uri, socket) do
    page = String.to_integer(params["page"] || "1")
    type_filter = params["type"]

    {:noreply,
     socket
     |> assign(:page, page)
     |> assign(:selected_type, type_filter)
     |> load_samples()}
  end

  def handle_event("filter_type", %{"type" => type}, socket) do
    {:noreply,
     socket
     |> assign(:selected_type, if(type == "", do: nil, else: type))
     |> assign(:page, 1)
     |> push_patch(to: build_path(socket, 1, if(type == "", do: nil, else: type)))}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    page = String.to_integer(page)
    {:noreply, push_patch(socket, to: build_path(socket, page, socket.assigns.selected_type))}
  end

  defp load_samples(socket) do
    result =
      HealthData.list_samples(
        page: socket.assigns.page,
        per_page: socket.assigns.per_page,
        type: socket.assigns.selected_type
      )

    # Get total count from ETS instead of expensive DB query
    total_count =
      if socket.assigns.selected_type do
        SampleCounter.get(socket.assigns.selected_type)
      else
        SampleCounter.get_all()
        |> Map.values()
        |> Enum.sum()
      end

    total_pages = ceil(total_count / socket.assigns.per_page)

    # Calculate start and end record numbers
    start_record = (socket.assigns.page - 1) * socket.assigns.per_page + 1
    end_record = start_record + length(result.samples) - 1

    socket
    |> assign(:samples, result.samples)
    |> assign(:start_record, start_record)
    |> assign(:end_record, end_record)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:has_more, result.has_more)
  end

  defp build_path(_socket, page, type) do
    query_params =
      [page: page, type: type]
      |> Enum.reject(fn {_k, v} -> is_nil(v) or v == 1 end)
      |> Enum.into(%{})

    if map_size(query_params) == 0 do
      ~p"/health/samples"
    else
      ~p"/health/samples?#{query_params}"
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Health Samples
        <:subtitle>
          Showing {@start_record}-{@end_record}{if @total_count, do: " of #{@total_count}", else: ""} samples
        </:subtitle>
        <:actions>
          <.button
            phx-click="goto_page"
            phx-value-page={@page - 1}
            disabled={@page <= 1}
          >
            Previous
          </.button>
          <.button
            phx-click="goto_page"
            phx-value-page={@page + 1}
            disabled={!@has_more}
          >
            Next
          </.button>
        </:actions>
      </.header>

      <div class="mb-4">
        <form phx-change="filter_type">
          <.input
            type="select"
            id="filter_type"
            name="type"
            label="Filter by Type"
            prompt="All Types"
            options={Enum.map(@sample_types, &{Formatter.humanize(&1), &1})}
            value={@selected_type}
          />
        </form>
      </div>

      <div class="overflow-x-auto">
        <.table id="samples" rows={@samples}>
          <:col :let={sample} label="Type">{Formatter.humanize(sample.type)}</:col>
          <:col :let={sample} label="Quantity">
            {Formatter.format_quantity(sample.quantity, sample.type)}
          </:col>
          <:col :let={sample} label="Start date">{Formatter.format_date(sample.start_date)}</:col>
          <:col :let={sample} label="End date">
            {Formatter.format_end_date(sample.start_date, sample.end_date)}
          </:col>
        </.table>
      </div>
    </Layouts.app>
    """
  end
end
