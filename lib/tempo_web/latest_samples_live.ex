defmodule TempoWeb.LatestSamplesLive do
  use TempoWeb, :live_view

  alias Tempo.HealthData
  alias Tempo.HealthData.Formatter

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Latest Samples")
     |> load_samples()}
  end

  defp load_samples(socket) do
    socket
    |> assign(:samples, HealthData.list_latest_samples())
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Latest Samples
        <:subtitle>
          Showing the most recent sample of each type ({@samples |> length()} types)
        </:subtitle>
      </.header>

      <.table id="latest-samples" rows={@samples}>
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
