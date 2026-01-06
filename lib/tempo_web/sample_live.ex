defmodule TempoWeb.SampleLive do
  use TempoWeb, :live_view

  alias Tempo.HealthData
  alias Tempo.HealthData.TypeTranslator

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
        Listing Samples
        <:subtitle>
          Showing {@samples |> length()} of {@total_count} samples
        </:subtitle>
      </.header>

      <div class="mb-4">
        <form phx-change="filter_type">
          <label for="type-filter" class="block text-sm font-medium">
            Filter by Type
          </label>
          <select
            id="type-filter"
            name="type"
            class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
          >
            <option value="">All Types</option>
            <option
              :for={type <- @sample_types}
              value={type}
              selected={type == @selected_type}
            >
              {TypeTranslator.humanize(type)}
            </option>
          </select>
        </form>
      </div>

      <.table id="samples" rows={@samples}>
        <:col :let={sample} label="Type">{TypeTranslator.humanize(sample.type)}</:col>
        <:col :let={sample} label="Quantity">{TypeTranslator.format_quantity(sample.quantity, sample.type)}</:col>
        <:col :let={sample} label="Start date">{TypeTranslator.format_date(sample.start_date)}</:col>
        <:col :let={sample} label="End date">{TypeTranslator.format_end_date(sample.start_date, sample.end_date)}</:col>
      </.table>

      <div class="mt-4 flex items-center justify-between">
        <div class="text-sm">
          Page {@page} of {@total_pages}
        </div>
        <div class="flex gap-2">
          <button
            :if={@page > 1}
            phx-click="goto_page"
            phx-value-page={@page - 1}
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            Previous
          </button>
          <button
            :if={@page < @total_pages}
            phx-click="goto_page"
            phx-value-page={@page + 1}
            class="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
          >
            Next
          </button>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
