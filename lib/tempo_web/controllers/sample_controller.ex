defmodule TempoWeb.SampleController do
  use TempoWeb, :controller

  alias Tempo.HealthData

  def index(conn, _params) do
    samples = HealthData.list_samples()
    render(conn, :index, samples: samples)
  end

  def show(conn, %{"id" => id}) do
    sample = HealthData.get_sample!(id)
    render(conn, :show, sample: sample)
  end
end
