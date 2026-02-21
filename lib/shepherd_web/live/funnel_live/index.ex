defmodule ShepherdWeb.FunnelLive.Index do
  use ShepherdWeb, :live_view

  import ShepherdWeb.DomainComponents

  alias Shepherd.LLM.CommandManager

  @impl true
  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id
    {:ok, commands} = CommandManager.get_pending_commands_by_type(user_id, "funnel")

    socket =
      socket
      |> assign(:page_title, "Funnel")
      |> assign(:active_section, "funnel")
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
        <.funnel_sidebar active_tab={@active_tab} />
      </div>

      <div class="flex-1 overflow-auto relative">
        <%= case @active_tab do %>
          <% "funnels" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Funnels ═══</span>
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
          <% "builder" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Builder ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Builder section content.</p>
            </div>
          <% "pages" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Pages ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Pages section content.</p>
            </div>
          <% "analytics" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Analytics ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Analytics section content.</p>
            </div>
          <% "conversions" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Conversions ═══</span>
                </div>
              </div>
              <p class="text-xs opacity-80">Conversions section content.</p>
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
                <div class="text-4xl mb-4">▼</div>
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
    {:noreply, push_patch(socket, to: ~p"/funnel?tab=#{tab}")}
  end

  def handle_event("command_done", %{"id" => id}, socket) do
    case CommandManager.complete_command(socket.assigns.user_id, id) do
      {:ok, _command} ->
        {:ok, commands} = CommandManager.get_pending_commands_by_type(socket.assigns.user_id, "funnel")
        {:noreply, socket |> assign(:commands, commands) |> refresh_notification_counts() |> put_flash(:info, "Command completed")}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not complete command")}
    end
  end

  def handle_event("command_dismiss", %{"id" => id}, socket) do
    case CommandManager.dismiss_command(socket.assigns.user_id, id) do
      {:ok, _command} ->
        {:ok, commands} = CommandManager.get_pending_commands_by_type(socket.assigns.user_id, "funnel")
        {:noreply, socket |> assign(:commands, commands) |> refresh_notification_counts() |> put_flash(:info, "Command dismissed")}
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not dismiss command")}
    end
  end

  def handle_event("command_push", %{"id" => _id}, socket) do
    {:noreply, put_flash(socket, :info, "Command pushed to queue")}
  end

  defp funnel_sidebar(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-terminal border-r-2 border-green-500 terminal-glow overflow-auto">
      <div class="p-4 border-b-2 border-green-500">
        <h2 class="text-sm font-bold uppercase text-green-400 text-center">▼ Funnel</h2>
      </div>

      <div class="flex-1 p-3">
        <div class="space-y-2">
          <.sidebar_nav_link navigate={~p"/funnel?tab=funnels"} active={@active_tab == "funnels"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Funnels</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/funnel?tab=builder"} active={@active_tab == "builder"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Builder</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/funnel?tab=pages"} active={@active_tab == "pages"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Pages</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/funnel?tab=analytics"} active={@active_tab == "analytics"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Analytics</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/funnel?tab=conversions"} active={@active_tab == "conversions"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Conversions</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/funnel?tab=settings"} active={@active_tab == "settings"}>
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
        "funnels" -> "Funnels"
        "builder" -> "Builder"
        "pages" -> "Pages"
        "analytics" -> "Analytics"
        "conversions" -> "Conversions"
        "settings" -> "Settings"
        _ -> "Funnel"
      end

    assign(socket, :page_title, title)
  end

end
