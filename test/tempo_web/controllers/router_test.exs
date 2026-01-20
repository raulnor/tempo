defmodule TempoWeb.RouterTest do
  @moduledoc """
  Smoke tests for route accessibility and basic page rendering. Each test verifies a route returns 200 and contains a page-unique header, ensuring the correct page is rendered. There should be one test per page.

  This approach is intentionally brittle—tests are tied to specific copy. They will fail if page content changes.
  """

  use TempoWeb.ConnCase

  describe "page routes" do
    test "GET /", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Measure more"
    end

    test "GET /health/samples", %{conn: conn} do
      conn = get(conn, ~p"/health/samples")
      assert html_response(conn, 200) =~ "Health Samples"
    end

    test "GET /health/latest", %{conn: conn} do
      conn = get(conn, ~p"/health/latest")
      assert html_response(conn, 200) =~ "Latest Samples"
    end

    test "GET /health/metrics", %{conn: conn} do
      conn = get(conn, ~p"/health/metrics")
      assert html_response(conn, 200) =~ "Health Metrics"
    end

    test "GET /health/readiness", %{conn: conn} do
      conn = get(conn, ~p"/health/readiness")
      assert html_response(conn, 200) =~ "HRV Readiness"
    end
  end
end
