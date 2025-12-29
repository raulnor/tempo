defmodule TempoWeb.PageController do
  use TempoWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
