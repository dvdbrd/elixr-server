defmodule ShepherdWeb.Router do
  use ShepherdWeb, :router

  import ShepherdWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ShepherdWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self' wss:"
    }
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug ShepherdWeb.Plugs.RateLimit, limit: 60, period: 60_000, prefix: "api"
  end

  pipeline :rate_limited_auth do
    plug ShepherdWeb.Plugs.RateLimit, limit: 5, period: 60_000, prefix: "auth"
  end

  scope "/", ShepherdWeb do
    pipe_through :browser

    live_session :default,
      on_mount: [{ShepherdWeb.UserAuth, :require_authenticated}],
      layout: {ShepherdWeb.Layouts, :app} do
      live "/", HqLive.Index, :index
      live "/hq2", HqLive.Index2, :index
      live "/hq3", HqLive.Index3, :index
      live "/hq4", HqLive.Index4, :index
      live "/website", WebsiteLive.Index, :index
      live "/app", AppLive.Index, :index
      live "/marketing", MarketingLive.Index, :index
      live "/funnel", FunnelLive.Index, :index
      live "/sales", SalesLive.Index, :index
      live "/hr", HrLive.Index, :index
      live "/customers", CustomersLive.Index, :index
      live "/terminal", TerminalLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  scope "/api", ShepherdWeb do
    pipe_through :api
    get "/health", HealthController, :check
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:shepherd, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ShepherdWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", ShepherdWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{ShepherdWeb.UserAuth, :require_authenticated}],
      layout: {ShepherdWeb.Layouts, :app} do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", ShepherdWeb do
    pipe_through [:browser, :rate_limited_auth]

    live_session :current_user,
      on_mount: [{ShepherdWeb.UserAuth, :mount_current_scope}],
      layout: false do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
