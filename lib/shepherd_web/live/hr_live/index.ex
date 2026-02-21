defmodule ShepherdWeb.HrLive.Index do
  use ShepherdWeb, :live_view

  import ShepherdWeb.DomainComponents

  alias Shepherd.LLM.CommandManager

  @impl true
  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, commands} = CommandManager.get_pending_commands_by_type(user_id, "hr")

    socket =
      socket
      |> assign(:page_title, "HR")
      |> assign(:active_section, "hr")
      |> assign(:active_tab, params["tab"])
      |> assign(:user_id, user_id)
      |> assign(:notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(user_id))
      |> assign(:commands, commands)

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
        <.hr_sidebar active_tab={@active_tab} />
      </div>

      <div class="flex-1 overflow-auto relative">
        <%= case @active_tab do %>
          <% "recruiting" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Recruiting ═══</span>
                </div>
              </div>

              <div class="space-y-3 max-w-3xl">
                <%= if @commands == [] do %>
                  <div class="border-2 border-green-500 bg-terminal terminal-glow p-6 text-center">
                    <p class="text-xs opacity-60">No pending commands</p>
                  </div>
                <% else %>
                  <%= for command <- @commands do %>
                    <.command_card
                      id={command.id}
                      title={command.command_text}
                      explanation={command.llm_reasoning || "No additional context"}
                    />
                  <% end %>
                <% end %>
              </div>
            </div>
          <% "onboarding" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Onboarding ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Onboarding section content.</p>
            </div>
          <% "performance" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Performance ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Performance section content.</p>
            </div>
          <% "team_events" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Team Events ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Team events section content.</p>
            </div>
          <% "policies" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Policies ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Policies section content.</p>
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
                <div class="text-4xl mb-4">◈</div>
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
    {:noreply, push_patch(socket, to: ~p"/hr?tab=#{tab}")}
  end

  def handle_event("command_done", %{"id" => id}, socket) do
    case CommandManager.complete_command(socket.assigns.user_id, id) do
      {:ok, _command} ->
        {:ok, commands} = CommandManager.get_pending_commands_by_type(socket.assigns.user_id, "hr")
        {:noreply, socket |> assign(:commands, commands) |> refresh_notification_counts() |> put_flash(:info, "Command completed")}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not complete command")}
    end
  end

  def handle_event("command_dismiss", %{"id" => id}, socket) do
    case CommandManager.dismiss_command(socket.assigns.user_id, id) do
      {:ok, _command} ->
        {:ok, commands} = CommandManager.get_pending_commands_by_type(socket.assigns.user_id, "hr")
        {:noreply, socket |> assign(:commands, commands) |> refresh_notification_counts() |> put_flash(:info, "Command dismissed")}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not dismiss command")}
    end
  end

  def handle_event("command_push", %{"id" => _id}, socket) do
    {:noreply, put_flash(socket, :info, "Command pushed to queue")}
  end

  defp hr_sidebar(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-terminal border-r-2 border-green-500 terminal-glow overflow-auto">
      <div class="p-4 border-b-2 border-green-500">
        <h2 class="text-sm font-bold uppercase text-green-400 text-center">◈ HR</h2>
      </div>

      <div class="flex-1 p-3">
        <div class="space-y-2">
          <.sidebar_nav_link navigate={~p"/hr?tab=recruiting"} active={@active_tab == "recruiting"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Recruiting</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/hr?tab=onboarding"} active={@active_tab == "onboarding"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Onboarding</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/hr?tab=performance"} active={@active_tab == "performance"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Performance</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/hr?tab=team_events"} active={@active_tab == "team_events"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Team Events</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/hr?tab=policies"} active={@active_tab == "policies"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Policies</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/hr?tab=reports"} active={@active_tab == "reports"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Reports</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/hr?tab=settings"} active={@active_tab == "settings"}>
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

  defp refresh_notification_counts(socket) do
    assign(socket, :notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(socket.assigns.user_id))
  end

  defp maybe_update_page_title(socket, tab) do
    title =
      case tab do
        "recruiting" -> "Recruiting"
        "onboarding" -> "Onboarding"
        "performance" -> "Performance"
        "team_events" -> "Team Events"
        "policies" -> "Policies"
        "reports" -> "Reports"
        "settings" -> "Settings"
        _ -> "HR"
      end

    assign(socket, :page_title, title)
  end

end
