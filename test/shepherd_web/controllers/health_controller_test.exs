defmodule ShepherdWeb.HealthControllerTest do
  use ShepherdWeb.ConnCase, async: true

  test "GET /api/health returns 200 with status ok", %{conn: conn} do
    conn = get(conn, ~p"/api/health")
    assert json_response(conn, 200) == %{"status" => "ok"}
  end

  test "GET /api/health returns JSON content-type", %{conn: conn} do
    conn = get(conn, ~p"/api/health")
    assert get_resp_header(conn, "content-type") |> hd() =~ "application/json"
  end
end
