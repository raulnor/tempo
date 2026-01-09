defmodule TempoWeb.SampleLive do
  use TempoWeb, :live_view

  alias Tempo.HealthData
  alias Tempo.HealthData.Formatter

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:sample_types, HealthData.list_sample_types())
     |> assign(:selected_type, nil)
     |> assign(:page, 1)
     |> assign(:page_title, "Health Samples")
     |> assign(:per_page, 20)
     |> load_samples()}
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

    socket
    |> assign(:samples, result.samples)
    |> assign(:start_record, result.start_record)
    |> assign(:end_record, result.end_record)
    |> assign(:total_count, result.total_count)
    |> assign(:total_pages, result.total_pages)
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
          Showing {@start_record}-{@end_record} of {@total_count} samples
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
            disabled={@page >= @total_pages}
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
    </Layouts.app>
    """
  end
end
