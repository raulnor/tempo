defmodule TempoWeb.Router do
  use TempoWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {TempoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TempoWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/health/samples", SampleLive
    live "/health/latest", LatestSamplesLive
  end

  scope "/api", TempoWeb do
    pipe_through :api

    post "/health/sync", HealthController, :sync
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:tempo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TempoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
