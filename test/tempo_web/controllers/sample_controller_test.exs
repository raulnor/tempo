defmodule TempoWeb.SampleControllerTest do
  use TempoWeb.ConnCase

  describe "index" do
    test "lists all samples", %{conn: conn} do
      conn = get(conn, ~p"/health/samples")
      assert html_response(conn, 200) =~ "Health Samples"
    end
  end
end
