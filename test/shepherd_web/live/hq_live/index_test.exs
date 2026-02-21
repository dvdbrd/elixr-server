defmodule ShepherdWeb.HqLive.IndexTest do
  use ShepherdWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "Index" do
    setup :register_and_log_in_user

    test "mounts successfully when authenticated", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "HQ"
    end

    test "renders the HQ terminal header", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "HQ - BUSINESS OPERATIONS COMMAND"
    end

    test "renders performance metrics section", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "PERFORMANCE METRICS"
    end

    test "renders domain cards", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "Website"
      assert html =~ "DOMAINS"
    end

    test "renders recent activity timeline", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "RECENT ACTIVITY TIMELINE"
    end

    test "renders manager feedback stream section", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")
      assert html =~ "MANAGER FEEDBACK STREAM"
    end

    test "redirects to login when not authenticated" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/")
      assert path =~ "/users/log-in"
    end
  end
end
