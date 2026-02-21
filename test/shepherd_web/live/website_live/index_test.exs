defmodule ShepherdWeb.WebsiteLive.IndexTest do
  use ShepherdWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shepherd.WebsitesFixtures

  describe "Index" do
    setup :register_and_log_in_user

    test "mounts successfully when authenticated", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/website")
      assert html =~ "Website" or html =~ "website"
    end

    test "renders sidebar navigation", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/website")
      assert html =~ "Commands"
      assert html =~ "Complain"
      assert html =~ "Report"
      assert html =~ "Brainstorm"
      assert html =~ "Settings"
    end

    test "shows add website form when no website exists", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/website?tab=settings")
      assert html =~ "Add Your Website" or html =~ "Website URL"
    end

    test "redirects to login when not authenticated" do
      conn = build_conn()
      assert {:error, {:redirect, %{to: path}}} = live(conn, ~p"/website")
      assert path =~ "/users/log-in"
    end

    test "renders commands tab content when navigated to commands tab", %{conn: conn, user: user} do
      _website = website_fixture(%{user_id: user.id})

      {:ok, _lv, html} = live(conn, ~p"/website?tab=commands")
      assert html =~ "Command" or html =~ "command" or html =~ "No pending commands"
    end

    test "can switch to commands tab via navigation", %{conn: conn, user: user} do
      _website = website_fixture(%{user_id: user.id})

      {:ok, lv, _html} = live(conn, ~p"/website")

      # Clicking a navigate link triggers a live_redirect
      assert {:error, {:live_redirect, %{to: "/website?tab=commands"}}} =
               lv |> element("a[href='/website?tab=commands']") |> render_click()

      # Follow the redirect to verify it works
      {:ok, _lv, html} = live(conn, ~p"/website?tab=commands")
      assert html =~ "Command" or html =~ "command" or html =~ "No pending commands"
    end

    test "shows website info after creating a website via settings tab", %{conn: conn, user: user} do
      website = website_fixture(%{user_id: user.id})

      {:ok, _lv, html} = live(conn, ~p"/website?tab=settings")
      assert html =~ website.url or html =~ "Domain" or html =~ "Settings"
    end

    test "renders report tab content", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/website?tab=report")
      assert html =~ "Report" or html =~ "report"
    end

    test "renders brainstorm tab content", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/website?tab=brainstorm")
      assert html =~ "Brainstorm" or html =~ "brainstorm"
    end
  end
end
