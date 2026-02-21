defmodule ShepherdWeb.SalesLive.Index do
  use ShepherdWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "Sales")
      |> assign(:active_section, "sales")
      |> assign(:active_tab, params["tab"])
      |> assign(:user_id, user_id)

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
        <.sales_sidebar active_tab={@active_tab} />
      </div>

      <div class="flex-1 overflow-auto relative">
        <%= case @active_tab do %>
          <% "pipeline" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Pipeline ═══</span>
                </div>
              </div>

              <div class="space-y-3 max-w-3xl">
                <.command_card
                  id="sales-pipeline-1"
                  title="Follow up with Enterprise Corp regarding Q1 proposal"
                  explanation="Schedule call to discuss their concerns about pricing and implementation timeline"
                />

                <.command_card
                  id="sales-pipeline-2"
                  title="Prepare pricing deck for healthcare vertical"
                  explanation="Create customized pricing presentation highlighting HIPAA compliance and healthcare-specific features"
                />

                <.command_card
                  id="sales-pipeline-3"
                  title="Schedule demo calls with 5 inbound leads from webinar"
                  explanation="Book product demos with qualified leads who registered for last week's webinar on AI automation"
                />
              </div>
            </div>
          <% "leads" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Leads ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Leads section content.</p>
            </div>
          <% "active_deals" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Active Deals ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Active deals section content.</p>
            </div>
          <% "follow_ups" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Follow-ups ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Follow-ups section content.</p>
            </div>
          <% "proposals" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Proposals ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Proposals section content.</p>
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
                <div class="text-4xl mb-4">◉</div>
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
    {:noreply, push_patch(socket, to: ~p"/sales?tab=#{tab}")}
  end

  def handle_event("command_done", %{"id" => _id}, socket) do
    {:noreply, put_flash(socket, :info, "Command marked as done")}
  end

  def handle_event("command_dismiss", %{"id" => _id}, socket) do
    {:noreply, put_flash(socket, :info, "Command dismissed")}
  end

  def handle_event("command_push", %{"id" => _id}, socket) do
    {:noreply, put_flash(socket, :info, "Command pushed to queue")}
  end

  defp sales_sidebar(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-terminal border-r-2 border-green-500 terminal-glow overflow-auto">
      <div class="p-4 border-b-2 border-green-500">
        <h2 class="text-sm font-bold uppercase text-green-400 text-center">◉ Sales</h2>
      </div>

      <div class="flex-1 p-3">
        <div class="space-y-2">
          <.sidebar_nav_link navigate={~p"/sales?tab=pipeline"} active={@active_tab == "pipeline"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Pipeline</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/sales?tab=leads"} active={@active_tab == "leads"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Leads</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/sales?tab=active_deals"} active={@active_tab == "active_deals"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Active Deals</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/sales?tab=follow_ups"} active={@active_tab == "follow_ups"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Follow-ups</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/sales?tab=proposals"} active={@active_tab == "proposals"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Proposals</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/sales?tab=reports"} active={@active_tab == "reports"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Reports</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/sales?tab=settings"} active={@active_tab == "settings"}>
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
        "pipeline" -> "Pipeline"
        "leads" -> "Leads"
        "active_deals" -> "Active Deals"
        "follow_ups" -> "Follow-ups"
        "proposals" -> "Proposals"
        "reports" -> "Reports"
        "settings" -> "Settings"
        _ -> "Sales"
      end

    assign(socket, :page_title, title)
  end

  attr :title, :string, required: true
  attr :explanation, :string, required: true
  attr :id, :string, required: true

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
          <button
            phx-click="command_done"
            phx-value-id={@id}
            class="border border-green-400 text-green-400 px-3 py-1 text-xs hover:bg-green-900 hover:bg-opacity-20 uppercase"
          >
            [Done]
          </button>
          <button
            phx-click="command_dismiss"
            phx-value-id={@id}
            class="border border-red-500 text-red-500 px-3 py-1 text-xs hover:bg-red-900 hover:bg-opacity-20 uppercase"
          >
            [No]
          </button>
          <button
            phx-click="command_push"
            phx-value-id={@id}
            class="border border-yellow-500 text-yellow-500 px-3 py-1 text-xs hover:bg-yellow-900 hover:bg-opacity-20 uppercase"
          >
            [Push]
          </button>
        </div>
      </div>
    </div>
    """
  end
end
