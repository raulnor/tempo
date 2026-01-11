defmodule TempoWeb.HomeLive do
  use TempoWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Main")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="py-10 sm:py-28 xl:py-32">
        <div class="mx-auto max-w-xl lg:mx-0">
          <p class="text-[2rem] mt-4 font-semibold leading-10 tracking-tighter text-balance">
            Measure more. Get stronger.
          </p>
          <p class="mt-4 leading-7 text-base-content/70">
            Tempo is a personal health data mining project. I'm trying to determine from the metrics I have how hard to push myself, and whether or not running is providing actual longevity.
          </p>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
