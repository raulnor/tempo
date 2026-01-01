defmodule TempoWeb.SampleLive do
  use TempoWeb, :live_view

  alias Tempo.HealthData

  def mount(_params, _session, socket) do
    {:ok, assign(socket, samples: HealthData.list_samples())}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Listing Samples
      </.header>
      <.table id="samples" rows={@samples}>
        <:col :let={sample} label="Type">{sample.type}</:col>
        <:col :let={sample} label="Quantity">{sample.quantity}</:col>
        <:col :let={sample} label="Start date">{sample.start_date}</:col>
        <:col :let={sample} label="End date">{sample.end_date}</:col>
      </.table>
    </Layouts.app>
    """
  end
end
