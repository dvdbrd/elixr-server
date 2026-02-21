defmodule ShepherdWeb.TerminalLive.Index do
  use ShepherdWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    socket =
      socket
      |> assign(:page_title, "Terminal")
      |> assign(:active_section, "terminal")
      |> assign(:uptime_seconds, 607337)
      |> assign(:system_load, 84)
      |> assign(:active_agents, 17)
      |> assign(:reduced_motion, false)
      |> assign_active_processes()
      |> assign_agent_status()
      |> assign_queue_data()
      |> assign_system_vitals()
      |> assign_log_entries()

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      socket
      |> update(:uptime_seconds, &(&1 + 1))
      |> update_processes()
      |> maybe_add_log_entry()

    {:noreply, socket}
  end

  @impl true
  def handle_event("refresh_ai", _params, socket) do
    socket =
      socket
      |> assign_active_processes()
      |> add_log_entry("SYSTEM", "AI refresh cycle initiated by user")

    {:noreply, socket}
  end

  @impl true
  def handle_event("emergency_stop", _params, socket) do
    socket =
      socket
      |> assign(:active_processes, [])
      |> add_log_entry("SYSTEM", "!! EMERGENCY STOP ACTIVATED !!", :critical)

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-auto terminal-screen">
      <!-- CRT Scanlines Effect -->
      <div class="scanlines pointer-events-none"></div>

      <div class="p-4 lg:p-6 relative">
        <!-- Terminal Header -->
        <div class="mb-6 border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 p-3">
            <!-- Animated indicators respect prefers-reduced-motion -->
            <div class="flex items-center gap-2 mb-2">
              <div class="w-2 h-2 rounded-full bg-red-500 motion-safe:animate-pulse"></div>
              <div class="w-2 h-2 rounded-full bg-yellow-500 motion-safe:animate-pulse"></div>
              <div class="w-2 h-2 rounded-full bg-green-500 motion-safe:animate-pulse"></div>
            </div>
            <div class="text-sm lg:text-base">
              SHEPHERD AI CONTROL SYSTEM v2.4.1
            </div>
            <div class="text-xs opacity-80 mt-1">
              SYSTEM.ID: SHEP-AI-001 | STATUS: OPERATIONAL | <%= @active_agents %> AGENTS LIVE
            </div>
            <div class="text-xs opacity-80">
              UPTIME: <%= format_uptime(@uptime_seconds) %> | LOAD: <%= render_bar(@system_load, 10) %> <%= @system_load %>%
            </div>
          </div>
        </div>

        <!-- Active Processes -->
        <div class="mb-6 border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">═══ ACTIVE PROCESSES ═══</span>
          </div>
          <div class="p-3 space-y-3">
            <%= if @active_processes == [] do %>
              <div class="text-center text-xs opacity-60 py-4">
                NO ACTIVE PROCESSES - SYSTEM HALTED
              </div>
            <% else %>
              <%= for process <- @active_processes do %>
                <div class="text-xs">
                  <div class="flex items-center gap-2">
                    <span class="text-green-400">►</span>
                    <span class="font-bold"><%= process.name %></span>
                    <span class="flex-1"></span>
                    <span>[<%= render_bar(process.progress, 10) %>]</span>
                    <span><%= process.progress %>%</span>
                    <span class="opacity-60">ETA: <%= process.eta %></span>
                  </div>
                  <div class="ml-4 opacity-75">
                    └─ <%= process.description %>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>

        <!-- Agent Status and Queue/Vitals Row -->
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
          <!-- Agent Status Matrix -->
          <div class="border-2 border-green-500 terminal-glow">
            <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
              <span class="text-sm font-bold text-green-400">═══ AGENT STATUS MATRIX ═══</span>
            </div>
            <div class="p-3">
              <div class="space-y-2 text-xs">
                <%= for agent <- @agent_status do %>
                  <div class="flex items-center gap-2">
                    <span class={["w-20", agent_status_class(agent.status)]}>
                      <%= agent.status_icon %> <%= agent.status %>
                    </span>
                    <span class="flex-1"><%= agent.name %></span>
                    <span class="opacity-60"><%= agent.tasks %> tasks</span>
                    <span class="opacity-60">| <%= agent.info %></span>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Queue and System Vitals Combined -->
          <div class="space-y-6">
            <!-- Queue -->
            <div class="border-2 border-green-500 terminal-glow">
              <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                <span class="text-sm font-bold text-green-400">═══ QUEUE ═══</span>
              </div>
              <div class="p-3 text-xs space-y-2">
                <div>
                  [<%= render_bar(@queue_data.total_percent, 12) %>] <%= @queue_data.total %> TASKS
                </div>
                <div class="space-y-1 opacity-80">
                  <div>MARKETING:     <%= String.pad_leading("#{@queue_data.marketing}", 3) %> tasks</div>
                  <div>SALES:         <%= String.pad_leading("#{@queue_data.sales}", 3) %> tasks</div>
                  <div>SUPPORT:       <%= String.pad_leading("#{@queue_data.support}", 3) %> tasks</div>
                  <div>ANALYTICS:     <%= String.pad_leading("#{@queue_data.analytics}", 3) %> tasks</div>
                </div>
                <div class="opacity-60 mt-2">EST. TIME: ~<%= @queue_data.est_time %> minutes</div>
              </div>
            </div>

            <!-- System Vitals -->
            <div class="border-2 border-green-500 terminal-glow">
              <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                <span class="text-sm font-bold text-green-400">═══ SYSTEM VITALS ═══</span>
              </div>
              <div class="p-3 text-xs space-y-1 opacity-80">
                <div>TOKENS: <%= @system_vitals.tokens_used %> / <%= @system_vitals.tokens_limit %> (<%= @system_vitals.tokens_percent %>%)</div>
                <div>API CALLS: <%= @system_vitals.api_calls %> / <%= @system_vitals.api_limit %> (<%= @system_vitals.api_percent %>%)</div>
                <div>AVG RESPONSE: <%= @system_vitals.avg_response %>ms</div>
                <div>CACHE HIT: <%= @system_vitals.cache_hit %>%</div>
                <div>SESSIONS: <%= @system_vitals.sessions %> active</div>
                <div>CPU LOAD: <%= @system_vitals.cpu_load %>% utilized</div>
                <div>MEMORY: <%= @system_vitals.memory_used %> / <%= @system_vitals.memory_total %></div>
                <div>DISK I/O: <%= @system_vitals.disk_io %> MB/s</div>
              </div>
            </div>
          </div>
        </div>

        <!-- Primary Controls -->
        <div class="mb-6 border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">═══ PRIMARY CONTROLS ═══</span>
          </div>
          <div class="p-4">
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
              <!-- Refresh Cycle -->
              <button
                phx-click="refresh_ai"
                class="border-2 border-green-500 text-green-500 p-6 bg-terminal hover:bg-green-900 hover:bg-opacity-30 hover:text-green-400 hover:border-green-400 transition-all terminal-glow text-left"
              >
                <div class="text-lg mb-2">↻ REFRESH CYCLE</div>
                <div class="text-xs opacity-75 mb-4">
                  Initialize clean AI<br />processing cycle
                </div>
                <div class="text-xs text-center border border-green-500 py-1 px-2 inline-block">
                  [PRESS TO EXECUTE]
                </div>
              </button>

              <!-- Emergency Stop -->
              <button
                phx-click="emergency_stop"
                class="border-2 border-red-500 text-red-500 p-6 bg-terminal hover:bg-red-900 hover:bg-opacity-30 hover:text-red-400 hover:border-red-400 transition-all terminal-glow-red text-left"
              >
                <div class="text-lg mb-2">⊗ EMERGENCY STOP</div>
                <div class="text-xs opacity-75 mb-4">
                  Immediate halt of all<br />AI operations
                </div>
                <div class="text-xs text-center border border-red-500 py-1 px-2 inline-block motion-safe:animate-pulse">
                  [!! PRESS TO HALT !!]
                </div>
              </button>
            </div>
          </div>
        </div>

        <!-- System Log -->
        <div class="border-2 border-green-500 terminal-glow">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">═══ SYSTEM LOG ═══</span>
          </div>
          <div class="p-3 text-xs space-y-1 h-64 overflow-y-auto log-container">
            <%= for entry <- Enum.take(@log_entries, -15) do %>
              <div class={log_entry_class(entry.severity)}>
                [<%= entry.timestamp %>] <%= entry.agent %> >> <%= entry.message %>
              </div>
            <% end %>
            <div class="opacity-75 motion-safe:animate-pulse">> _</div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Helper Functions

  defp assign_active_processes(socket) do
    processes = [
      %{
        name: "CONTENT_GENERATION_01",
        description: "Processing batch 47/89... 2.4MB data analyzed",
        progress: 67,
        eta: "04:23"
      },
      %{
        name: "LEAD_QUALIFICATION_03",
        description: "Analyzing 12 leads... pattern matching in progress",
        progress: 40,
        eta: "08:15"
      },
      %{
        name: "SENTIMENT_ANALYSIS_02",
        description: "Processing 2,847 messages... sentiment mapping active",
        progress: 78,
        eta: "02:45"
      },
      %{
        name: "MARKETING_OPTIMIZER_01",
        description: "Campaign analysis... calculating ROI projections",
        progress: 23,
        eta: "12:08"
      }
    ]

    assign(socket, :active_processes, processes)
  end

  defp assign_agent_status(socket) do
    agents = [
      %{name: "CONTENT_GENERATOR", status: "ACTIVE", status_icon: "●", tasks: 47, info: "LAST: 00:00:12"},
      %{name: "SALES_QUALIFIER", status: "PROC", status_icon: "●", tasks: 3, info: "ETA: 00:04:00"},
      %{name: "SUPPORT_RESPONDER", status: "IDLE", status_icon: "○", tasks: 0, info: "LAST: 00:03:24"},
      %{name: "ANALYTICS_ENGINE", status: "ACTIVE", status_icon: "●", tasks: 1, info: "DATASET#23"},
      %{name: "MARKETING_OPTIMIZER", status: "QUEUE", status_icon: "■", tasks: 8, info: "WAIT: 00:08:30"},
      %{name: "CUSTOMER_INTEL", status: "ACTIVE", status_icon: "●", tasks: 12, info: "PATTERNS"},
      %{name: "EMAIL_COMPOSER", status: "IDLE", status_icon: "○", tasks: 0, info: "LAST: 00:15:42"},
      %{name: "PRICE_ANALYZER", status: "ACTIVE", status_icon: "●", tasks: 5, info: "MARKET_01"}
    ]

    assign(socket, :agent_status, agents)
  end

  defp assign_queue_data(socket) do
    queue = %{
      total: 234,
      total_percent: 65,
      marketing: 89,
      sales: 67,
      support: 45,
      analytics: 33,
      est_time: 47
    }

    assign(socket, :queue_data, queue)
  end

  defp assign_system_vitals(socket) do
    vitals = %{
      tokens_used: "2.4M",
      tokens_limit: "5.0M",
      tokens_percent: 48,
      api_calls: "847K",
      api_limit: "1.0M",
      api_percent: 84,
      avg_response: 847,
      cache_hit: 91.3,
      sessions: 17,
      cpu_load: 84,
      memory_used: "12.4GB",
      memory_total: "16.0GB",
      disk_io: 234
    }

    assign(socket, :system_vitals, vitals)
  end

  defp assign_log_entries(socket) do
    entries = [
      %{timestamp: "14:23:47", agent: "CONTENT_GEN_01", message: "Blog post #847 completed (2.4KB)", severity: :normal},
      %{timestamp: "14:23:52", agent: "SALES_QUAL_03", message: "Lead #1847 flagged [HIGH_PRIORITY]", severity: :warning},
      %{timestamp: "14:24:01", agent: "SUPPORT_AI_02", message: "Ticket #923 auto-response sent", severity: :normal},
      %{timestamp: "14:24:15", agent: "ANALYTICS_05", message: "Pattern detected: +34% signup rate", severity: :warning},
      %{timestamp: "14:24:28", agent: "MARKETING_01", message: "Campaign #12 performance analyzed", severity: :normal},
      %{timestamp: "14:24:35", agent: "CONTENT_GEN_01", message: "Starting batch #48 (23 items)", severity: :normal},
      %{timestamp: "14:24:41", agent: "SALES_QUAL_03", message: "3 new leads added to processing queue", severity: :normal},
      %{timestamp: "14:24:58", agent: "PRICE_ANAL_04", message: "Market analysis complete (competitor)", severity: :normal}
    ]

    assign(socket, :log_entries, entries)
  end

  defp update_processes(socket) do
    # Update progress bars - increment each by 1-3% randomly
    updated_processes =
      Enum.map(socket.assigns.active_processes, fn process ->
        new_progress = min(process.progress + Enum.random(1..3), 100)
        %{process | progress: new_progress}
      end)

    assign(socket, :active_processes, updated_processes)
  end

  defp maybe_add_log_entry(socket) do
    # Add a new log entry every ~3-5 seconds (randomly)
    if Enum.random(1..5) == 1 do
      add_random_log_entry(socket)
    else
      socket
    end
  end

  defp add_random_log_entry(socket) do
    messages = [
      {"CONTENT_GEN_01", "Processing article batch ##{Enum.random(10..99)}", :normal},
      {"SALES_QUAL_03", "Lead qualification in progress", :normal},
      {"SUPPORT_AI_02", "Ticket ##{Enum.random(100..999)} resolved automatically", :normal},
      {"ANALYTICS_05", "Data pattern analysis complete", :normal},
      {"MARKETING_01", "Campaign optimization cycle complete", :normal},
      {"CUSTOMER_INT_06", "Customer behavior analysis running", :normal},
      {"EMAIL_COMP_02", "Email draft generated for review", :normal},
      {"PRICE_ANAL_04", "Competitor pricing scan initiated", :normal}
    ]

    {agent, message, severity} = Enum.random(messages)
    add_log_entry(socket, agent, message, severity)
  end

  defp add_log_entry(socket, agent, message, severity \\ :normal) do
    entry = %{
      timestamp: format_timestamp(DateTime.utc_now()),
      agent: agent,
      message: message,
      severity: severity
    }

    update(socket, :log_entries, fn entries -> entries ++ [entry] end)
  end

  defp format_uptime(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    secs = rem(seconds, 60)

    "#{String.pad_leading("#{hours}", 3, "0")}:#{String.pad_leading("#{minutes}", 2, "0")}:#{String.pad_leading("#{secs}", 2, "0")}"
  end

  defp format_timestamp(datetime) do
    Calendar.strftime(datetime, "%H:%M:%S")
  end

  defp render_bar(percentage, width) do
    filled = round(percentage / 100 * width)
    empty = width - filled

    String.duplicate("█", filled) <> String.duplicate("░", empty)
  end

  defp agent_status_class(status) do
    case status do
      "ACTIVE" -> "text-green-400"
      "PROC" -> "text-green-400"
      "IDLE" -> "opacity-50"
      "QUEUE" -> "text-yellow-500"
      _ -> ""
    end
  end

  defp log_entry_class(severity) do
    case severity do
      :critical -> "text-red-500 motion-safe:animate-pulse"
      :warning -> "text-yellow-500"
      :normal -> "opacity-80"
      _ -> "opacity-80"
    end
  end
end
