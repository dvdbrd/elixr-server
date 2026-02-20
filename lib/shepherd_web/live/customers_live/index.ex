defmodule ShepherdWeb.CustomersLive.Index do
  use ShepherdWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Customers")
      |> assign(:active_section, "customers")
      |> assign(:active_tab, params["tab"])

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = params["tab"]

    socket =
      socket
      |> assign(:active_tab, tab)
      |> maybe_update_page_title(tab)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-hidden terminal-screen flex">
      <!-- CRT Scanlines Effect -->
      <div class="scanlines pointer-events-none"></div>

      <div class="w-80 flex-shrink-0 relative">
        <.customers_sidebar active_tab={@active_tab} />
      </div>

      <div class="flex-1 overflow-auto relative">
        <%= case @active_tab do %>
          <% "support" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Support ═══</span>
                </div>
              </div>

              <div class="space-y-3 max-w-3xl">
                <.command_card
                  title="Respond to support ticket #1247 about billing discrepancy"
                  explanation="Customer reports double charge on their invoice, investigate and resolve the billing issue"
                />

                <.command_card
                  title="Send onboarding email sequence to 15 new customers"
                  explanation="Trigger welcome email series for customers who signed up in the last 24 hours"
                />

                <.command_card
                  title="Schedule quarterly business review with top 3 accounts"
                  explanation="Book QBR meetings with Enterprise Corp, Tech Solutions Inc, and Global Systems Ltd"
                />
              </div>
            </div>
          <% "feedback" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Feedback ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Feedback section content.</p>
            </div>
          <% "accounts" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Accounts ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Accounts section content.</p>
            </div>
          <% "health_score" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Health Score ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Health score section content.</p>
            </div>
          <% "renewals" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Renewals ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Renewals section content.</p>
            </div>
          <% "reports" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Reports ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Reports section content.</p>
            </div>
          <% "settings" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Settings ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Settings section content.</p>
            </div>
          <% nil -> %>
            <div class="flex items-center justify-center min-h-full">
              <div class="text-center border-2 border-green-500 terminal-glow p-8">
                <div class="text-4xl mb-4">◍</div>
                <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                  Select a section
                </h3>
                <p class="text-xs opacity-60">
                  Choose a section from the sidebar
                </p>
              </div>
            </div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/customers?tab=#{tab}")}
  end

  defp customers_sidebar(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-terminal border-r-2 border-green-500 terminal-glow overflow-auto">
      <div class="p-4 border-b-2 border-green-500">
        <h2 class="text-sm font-bold uppercase text-green-400 text-center">◍ Customers</h2>
      </div>

      <div class="flex-1 p-3">
        <div class="space-y-2">
          <.sidebar_nav_link navigate={~p"/customers?tab=support"} active={@active_tab == "support"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Support</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/customers?tab=feedback"} active={@active_tab == "feedback"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Feedback</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/customers?tab=accounts"} active={@active_tab == "accounts"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Accounts</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link
            navigate={~p"/customers?tab=health_score"}
            active={@active_tab == "health_score"}
          >
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Health Score</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/customers?tab=renewals"} active={@active_tab == "renewals"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Renewals</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/customers?tab=reports"} active={@active_tab == "reports"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Reports</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/customers?tab=settings"} active={@active_tab == "settings"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Settings</div>
            </div>
          </.sidebar_nav_link>
        </div>
      </div>
    </div>
    """
  end

  defp sidebar_nav_link(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      class={[
        "flex items-center w-full px-3 py-2 border transition-colors",
        if(@active,
          do: "bg-green-500 bg-opacity-20 border-green-400 text-green-300",
          else: "bg-terminal border-green-500 border-opacity-30 text-green-500 opacity-60 hover:bg-green-500 hover:bg-opacity-20 hover:border-green-400 hover:text-green-300 hover:opacity-100"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp maybe_update_page_title(socket, tab) do
    title =
      case tab do
        "support" -> "Support"
        "feedback" -> "Feedback"
        "accounts" -> "Accounts"
        "health_score" -> "Health Score"
        "renewals" -> "Renewals"
        "reports" -> "Reports"
        "settings" -> "Settings"
        _ -> "Customers"
      end

    assign(socket, :page_title, title)
  end

  attr :title, :string, required: true
  attr :explanation, :string, required: true

  defp command_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal terminal-glow">
      <div class="p-3">
        <div class="flex items-start justify-between gap-4 mb-3">
          <h3 class="text-sm font-bold flex-1">{@title}</h3>

          <div class="relative group">
            <button class="border border-green-500 px-2 py-1 text-xs hover:bg-green-900 hover:bg-opacity-20">
              [?]
            </button>

            <div class="absolute right-0 top-full mt-2 w-64 p-3 bg-terminal border-2 border-green-500 terminal-glow opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-10">
              <p class="text-xs opacity-90">{@explanation}</p>
            </div>
          </div>
        </div>

        <div class="flex gap-2 justify-end">
          <button class="border border-green-400 text-green-400 px-3 py-1 text-xs hover:bg-green-900 hover:bg-opacity-20 uppercase">
            [Done]
          </button>
          <button class="border border-red-500 text-red-500 px-3 py-1 text-xs hover:bg-red-900 hover:bg-opacity-20 uppercase">
            [No]
          </button>
          <button class="border border-yellow-500 text-yellow-500 px-3 py-1 text-xs hover:bg-yellow-900 hover:bg-opacity-20 uppercase">
            [Push]
          </button>
        </div>
      </div>
    </div>
    """
  end
end
