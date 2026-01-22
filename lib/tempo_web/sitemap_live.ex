defmodule TempoWeb.SitemapLive do
  use TempoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Sitemap")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
    <.header>
          Sitemap
          <:subtitle>
            All available pages in Tempo
          </:subtitle>
          <:actions>
            <Layouts.theme_toggle />
          </:actions>
        </.header>
      <div class="space-y-10" style="margin-top: 32px;">
          <!-- Main Pages -->
          <div>
            <h3 class="text-lg font-semibold mb-3">Main Pages</h3>
            <ul class="space-y-2">
              <li>
                <.link navigate="/" class="link link-primary font-medium">Home</.link>
                - Main landing page with project overview
              </li>
              <li>
                <.link navigate="/sitemap" class="link link-primary font-medium">Sitemap</.link>
                - All available pages in Tempo
              </li>
            </ul>
          </div>
          <!-- Health Data Pages -->
          <div>
            <h3 class="text-lg font-semibold mb-3">Health Data</h3>
            <ul class="space-y-2">
              <li>
                <.link navigate="/health/readiness" class="link link-primary font-medium">
                  HRV Readiness
                </.link>
                - Morning HRV readiness index with 7-day trend chart
              </li>
              <li>
                <.link navigate="/health/metrics" class="link link-primary font-medium">Metrics</.link>
                - Health metrics overview and visualization
              </li>
              <li>
                <.link navigate="/health/samples" class="link link-primary font-medium">Samples</.link>
                - Browse all health data samples
              </li>
              <li>
                <.link navigate="/health/latest" class="link link-primary font-medium">
                  Latest Samples
                </.link>
                - View most recent health data samples
              </li>
            </ul>
          </div>
        </div>
    </Layouts.app>
    """
  end
end
