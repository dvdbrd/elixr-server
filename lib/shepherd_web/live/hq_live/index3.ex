defmodule ShepherdWeb.HqLive.Index3 do
  use ShepherdWeb, :live_view
  alias Shepherd.LLM.{ContextManager, UserCommand}
  alias Shepherd.Repo
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(2000, self(), :tick)
    end

    user_id = socket.assigns.current_scope.user.id

    socket =
      socket
      |> assign(:page_title, "HQ v3")
      |> assign(:active_section, "hq")
      |> assign(:view_mode, "threat")
      |> assign(:focused_domain, nil)
      |> assign(:triage_index, 0)
      |> assign(:command_input, "")
      |> assign(:user_id, user_id)
      |> assign_signals(user_id)
      |> assign_domain_pulse()

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    user_id = socket.assigns.user_id

    socket =
      socket
      |> assign_signals(user_id)
      |> update_domain_pulse()

    {:noreply, socket}
  end

  @impl true
  def handle_event("switch_mode", %{"mode" => mode}, socket) do
    {:noreply, assign(socket, :view_mode, mode)}
  end

  @impl true
  def handle_event("focus_domain", %{"domain" => domain}, socket) do
    new_domain = if domain in ["all", "clear"], do: nil, else: if(socket.assigns.focused_domain == domain, do: nil, else: domain)
    {:noreply, assign(socket, :focused_domain, new_domain)}
  end

  @impl true
  def handle_event("triage_deploy", _params, socket) do
    user_id = socket.assigns.user_id
    index = socket.assigns.triage_index
    signals = socket.assigns.signals

    if index >= 0 and index < length(signals) do
      current_signal = Enum.at(signals, index)
      # Mark command as completed in database
      ContextManager.mark_command_completed(user_id, current_signal.command_id)

      {:noreply, remove_current_signal(socket)}
    else
      {:noreply, assign(socket, :triage_index, 0)}
    end
  end

  @impl true
  def handle_event("triage_defer", _params, socket) do
    signals = socket.assigns.signals
    index = socket.assigns.triage_index

    if index >= 0 and index < length(signals) do
      # Defer just advances past the current item without changing its status
      {:noreply, advance_triage(socket)}
    else
      {:noreply, assign(socket, :triage_index, 0)}
    end
  end

  @impl true
  def handle_event("triage_skip", _params, socket) do
    index = socket.assigns.triage_index
    signals = socket.assigns.signals

    if index >= 0 and index < length(signals) do
      {:noreply, advance_triage(socket)}
    else
      {:noreply, assign(socket, :triage_index, 0)}
    end
  end

  @impl true
  def handle_event("signal_action", %{"id" => id, "action" => action}, socket) do
    case Integer.parse(id) do
      {signal_id, _} ->
        user_id = socket.assigns.user_id
        signal = Enum.find(socket.assigns.signals, fn s -> s.id == signal_id end)

        if signal do
          if action in ["deploy"] do
            ContextManager.mark_command_completed(user_id, signal.command_id)
          end

          {:noreply, remove_signal(socket, signal_id)}
        else
          {:noreply, socket}
        end

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("submit_command", %{"command" => command}, socket) do
    trimmed = String.trim(command)

    if trimmed != "" do
      user_id = socket.assigns.user_id
      domain = extract_domain(trimmed)

      attrs = %{
        user_id: user_id,
        command_text: trimmed,
        urgency: "medium",
        status: "pending",
        created_by: "user",
        entity_type: String.downcase(domain)
      }

      case Repo.insert(UserCommand.changeset(%UserCommand{}, attrs)) do
        {:ok, _command} ->
          socket =
            socket
            |> assign(:command_input, "")
            |> assign_signals(user_id)

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, assign(socket, :command_input, "")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_command", params, socket) do
    value = params["value"] || params["command"] || ""
    {:noreply, assign(socket, :command_input, value)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-hidden terminal-screen flex flex-col">
      <div class="scanlines pointer-events-none"></div>

      <!-- Dynamic Header -->
      <div class="border-b-2 border-green-500 relative">
        <div class="p-3 flex items-center justify-between">
          <div class="flex items-center gap-4">
            <div class="text-sm font-bold">HQ</div>
            <div class="text-xs opacity-40">
              [<.link navigate="/" class="hover:text-green-300">v1</.link> |
              <.link navigate="/hq2" class="hover:text-green-300">v2</.link> |
              <span class="text-green-400">v3</span>]
            </div>
          </div>

          <!-- Mode Switcher -->
          <div class="flex gap-2 text-xs">
            <button
              phx-click="switch_mode"
              phx-value-mode="threat"
              class={mode_button_class(@view_mode, "threat")}
            >
              THREAT
            </button>
            <button
              phx-click="switch_mode"
              phx-value-mode="pulse"
              class={mode_button_class(@view_mode, "pulse")}
            >
              PULSE
            </button>
            <button
              phx-click="switch_mode"
              phx-value-mode="domain"
              class={mode_button_class(@view_mode, "domain")}
            >
              DOMAIN
            </button>
            <button
              phx-click="switch_mode"
              phx-value-mode="triage"
              class={mode_button_class(@view_mode, "triage")}
            >
              TRIAGE
            </button>
          </div>
        </div>
      </div>

      <!-- Dynamic Content Area -->
      <div class="flex-1 overflow-auto relative p-4">
        <%= case @view_mode do %>
          <% "threat" -> %>
            <.threat_view signals={@signals} focused_domain={@focused_domain} />
          <% "pulse" -> %>
            <.pulse_view domain_pulse={@domain_pulse} signals={@signals} />
          <% "domain" -> %>
            <.domain_view domain_pulse={@domain_pulse} focused_domain={@focused_domain} />
          <% "triage" -> %>
            <.triage_view signals={@signals} triage_index={@triage_index} />
        <% end %>
      </div>

      <!-- Command Bar - Always Present -->
      <div class="border-t-2 border-green-500 p-2 bg-terminal">
        <form phx-submit="submit_command" class="flex items-center gap-2">
          <span class="text-green-400">></span>
          <input
            type="text"
            name="command"
            value={@command_input}
            phx-change="update_command"
            placeholder="command..."
            class="flex-1 bg-transparent outline-none text-green-500 placeholder-green-500 placeholder-opacity-30 text-sm"
            autocomplete="off"
          />
          <button type="submit" class="text-xs opacity-60 hover:opacity-100">[ENTER]</button>
        </form>
      </div>
    </div>
    """
  end

  # THREAT VIEW - Fluid priority layout
  attr :signals, :list, required: true
  attr :focused_domain, :string, default: nil

  defp threat_view(assigns) do
    # Filter by focused domain if set
    filtered_signals =
      if assigns.focused_domain do
        Enum.filter(assigns.signals, fn s -> s.domain == assigns.focused_domain end)
      else
        assigns.signals
      end

    # Sort by priority score
    sorted_signals =
      filtered_signals
      |> Enum.sort_by(& &1.priority, :desc)

    assigns = assign(assigns, :sorted_signals, sorted_signals)

    ~H"""
    <div class="space-y-4">
      <!-- Domain Filter Pills -->
      <div class="flex flex-wrap gap-2 mb-6 pb-4 border-b border-green-500 border-opacity-30">
        <button
          phx-click="focus_domain"
          phx-value-domain="all"
          class={[
            "px-3 py-1 border text-xs transition-all",
            if(@focused_domain == nil,
              do: "border-green-400 text-green-400 bg-green-900 bg-opacity-20",
              else: "border-green-500 border-opacity-30 text-green-500 opacity-60 hover:opacity-100"
            )
          ]}
        >
          ALL
        </button>
        <%= for domain <- ["Sales", "App", "Customers", "Marketing", "Website", "HR"] do %>
          <button
            phx-click="focus_domain"
            phx-value-domain={domain}
            class={[
              "px-3 py-1 border text-xs transition-all",
              if(@focused_domain == domain,
                do: "border-green-400 text-green-400 bg-green-900 bg-opacity-20",
                else: "border-green-500 border-opacity-30 text-green-500 opacity-60 hover:opacity-100"
              )
            ]}
          >
            {domain}
          </button>
        <% end %>
      </div>

      <!-- Fluid Signal Grid -->
      <div class="grid grid-cols-12 gap-3 auto-rows-min">
        <%= for signal <- @sorted_signals do %>
          <.signal_card signal={signal} />
        <% end %>
      </div>

      <%= if @sorted_signals == [] do %>
        <div class="text-center py-20 opacity-40 text-sm">
          ALL CLEAR - NO ACTIVE THREATS
        </div>
      <% end %>
    </div>
    """
  end

  # PULSE VIEW - Analytics focused, velocity visible
  attr :domain_pulse, :list, required: true
  attr :signals, :list, required: true

  defp pulse_view(assigns) do
    ~H"""
    <div class="space-y-6">
      <!-- System Pulse -->
      <div class="border-2 border-green-500 p-4">
        <div class="text-xs font-bold mb-4 text-green-400">═══ SYSTEM PULSE ═══</div>
        <div class="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <div class="text-2xl font-bold"><%= length(@signals) %></div>
            <div class="text-xs opacity-60 mt-1">ACTIVE SIGNALS</div>
            <div class="text-xs opacity-60 mt-1">
              <%= critical_count(@signals) %> critical
            </div>
          </div>
          <div>
            <div class="text-2xl font-bold text-red-500"><%= escalating_count(@signals) %></div>
            <div class="text-xs opacity-60 mt-1">ESCALATING ↗</div>
            <div class="text-xs text-red-500 opacity-80 mt-1">Requires attention</div>
          </div>
          <div>
            <div class="text-2xl font-bold text-green-400"><%= improving_count(@signals) %></div>
            <div class="text-xs opacity-60 mt-1">IMPROVING ↘</div>
            <div class="text-xs text-green-400 opacity-80 mt-1">Trending positive</div>
          </div>
          <div>
            <div class="text-2xl font-bold"><%= ops_active_count() %></div>
            <div class="text-xs opacity-60 mt-1">OPS ACTIVE</div>
            <div class="text-xs opacity-60 mt-1">AI working</div>
          </div>
        </div>
      </div>

      <%= if @signals == [] do %>
        <div class="text-center py-8 opacity-40 text-sm border border-green-500 border-opacity-30">
          No pending signals. All clear.
        </div>
      <% end %>

      <!-- Domain Pulse Cards -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <%= for domain <- @domain_pulse do %>
          <.domain_pulse_card domain={domain} />
        <% end %>
      </div>

      <!-- Recent Velocity Changes -->
      <div class="border-2 border-green-500 p-4">
        <div class="text-xs font-bold mb-4 text-green-400">═══ VELOCITY CHANGES (24H) ═══</div>
        <div class="space-y-2 text-xs">
          <div class="flex items-center gap-2">
            <span class="text-red-500">↗↗↗</span>
            <span class="flex-1">Sales pipeline stalls increased 45%</span>
            <span class="opacity-60">-45%</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-green-400">↘↘</span>
            <span class="flex-1">App response time improved</span>
            <span class="opacity-60">+23%</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-yellow-500">↗</span>
            <span class="flex-1">Marketing conversion rate declining</span>
            <span class="opacity-60">-8%</span>
          </div>
          <div class="flex items-center gap-2">
            <span class="text-green-400">↘</span>
            <span class="flex-1">Customer support tickets resolved faster</span>
            <span class="opacity-60">+12%</span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # DOMAIN VIEW - Focus on one domain at a time
  attr :domain_pulse, :list, required: true
  attr :focused_domain, :string, default: nil

  defp domain_view(assigns) do
    ~H"""
    <div class="space-y-4">
      <!-- Domain Selector -->
      <div class="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <%= for domain <- @domain_pulse do %>
          <button
            phx-click="focus_domain"
            phx-value-domain={domain.name}
            class={[
              "border-2 p-4 text-left transition-all",
              if(@focused_domain == domain.name,
                do: "border-green-400 bg-green-900 bg-opacity-20",
                else: "border-green-500 border-opacity-30 hover:border-green-400"
              )
            ]}
          >
            <div class="flex items-center justify-between mb-2">
              <div class="text-sm font-bold">{domain.name}</div>
              <span class={health_class(domain.health)}>{health_symbol(domain.health)}</span>
            </div>
            <div class="text-xs opacity-60">
              {domain.active} active | {domain.pending} pending
            </div>
            <div class="text-xs opacity-40 mt-1">
              {domain.velocity_symbol} {domain.velocity_text}
            </div>
          </button>
        <% end %>
      </div>

      <!-- Focused Domain Detail -->
      <%= if @focused_domain do %>
        <div class="border-2 border-green-500 p-6 mt-6">
          <div class="text-lg font-bold mb-4 text-green-400">
            {String.upcase(@focused_domain)} - DETAIL VIEW
          </div>

          <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
            <div>
              <div class="text-xs opacity-60 mb-2">HEALTH STATUS</div>
              <div class="text-2xl font-bold">OPERATIONAL</div>
            </div>
            <div>
              <div class="text-xs opacity-60 mb-2">ACTIVE OPERATIONS</div>
              <div class="text-2xl font-bold">3</div>
            </div>
            <div>
              <div class="text-xs opacity-60 mb-2">PENDING COMMANDS</div>
              <div class="text-2xl font-bold">7</div>
            </div>
          </div>

          <div class="border-t border-green-500 border-opacity-30 pt-4">
            <div class="text-xs font-bold mb-3">RECENT ACTIVITY</div>
            <div class="space-y-2 text-xs">
              <div class="flex items-start gap-2 opacity-80">
                <span class="text-green-400">►</span>
                <span class="flex-1">Draft follow-up email for Enterprise deal</span>
                <span class="opacity-60">2m ago</span>
              </div>
              <div class="flex items-start gap-2 opacity-80">
                <span class="text-yellow-500">◐</span>
                <span class="flex-1">Analyzing competitor pricing strategy</span>
                <span class="opacity-60">5m ago</span>
              </div>
              <div class="flex items-start gap-2 opacity-80">
                <span class="text-green-400">►</span>
                <span class="flex-1">Generated Q1 revenue forecast</span>
                <span class="opacity-60">12m ago</span>
              </div>
            </div>
          </div>

          <div class="mt-6 flex gap-2">
            <.link
              navigate={"/" <> String.downcase(@focused_domain)}
              class="border border-green-500 px-4 py-2 text-xs hover:bg-green-900 hover:bg-opacity-20"
            >
              [OPEN {String.upcase(@focused_domain)}]
            </.link>
            <button
              phx-click="focus_domain"
              phx-value-domain="clear"
              class="border border-green-500 border-opacity-30 px-4 py-2 text-xs opacity-60 hover:opacity-100"
            >
              [CLOSE]
            </button>
          </div>
        </div>
      <% else %>
        <div class="text-center py-20 opacity-40 text-sm">
          SELECT A DOMAIN ABOVE
        </div>
      <% end %>
    </div>
    """
  end

  # TRIAGE VIEW - Rapid decision making
  attr :signals, :list, required: true
  attr :triage_index, :integer, required: true

  defp triage_view(assigns) do
    current_signal =
      if assigns.triage_index < length(assigns.signals) do
        Enum.at(assigns.signals, assigns.triage_index)
      else
        nil
      end

    assigns = assign(assigns, :current_signal, current_signal)

    ~H"""
    <div class="flex items-center justify-center min-h-full">
      <%= if @current_signal do %>
        <div class="max-w-2xl w-full">
          <!-- Progress -->
          <div class="text-center mb-6 text-xs opacity-60">
            TRIAGE: <%= @triage_index + 1 %> / <%= length(@signals) %>
          </div>

          <!-- Signal Card - Large -->
          <div class={[
            "border-4 p-8",
            signal_severity_border(@current_signal.severity)
          ]}>
            <div class="text-center mb-6">
              <div class={[
                "text-xs font-bold mb-2",
                signal_severity_text(@current_signal.severity)
              ]}>
                <%= @current_signal.severity %> | <%= @current_signal.domain %>
              </div>
              <div class="text-xl font-bold mb-4">
                <%= @current_signal.title %>
              </div>
              <div class="text-sm opacity-80 mb-4">
                <%= @current_signal.description %>
              </div>
            </div>

            <!-- Metrics -->
            <div class="grid grid-cols-3 gap-4 mb-6 pb-6 border-b border-green-500 border-opacity-30">
              <div class="text-center">
                <div class="text-xs opacity-60 mb-1">IMPACT</div>
                <div class="text-sm font-bold"><%= @current_signal.impact %></div>
              </div>
              <div class="text-center">
                <div class="text-xs opacity-60 mb-1">AGE</div>
                <div class="text-sm font-bold"><%= @current_signal.age %></div>
              </div>
              <div class="text-center">
                <div class="text-xs opacity-60 mb-1">VELOCITY</div>
                <div class={["text-sm font-bold", velocity_color(@current_signal.velocity)]}>
                  <%= @current_signal.velocity_symbol %> <%= @current_signal.velocity %>
                </div>
              </div>
            </div>

            <!-- Triage Actions -->
            <div class="grid grid-cols-3 gap-3">
              <button
                phx-click="triage_deploy"
                class="border-2 border-green-500 text-green-500 py-4 hover:bg-green-900 hover:bg-opacity-30 transition-all font-bold text-sm"
              >
                [D] DEPLOY<br />
                <span class="text-xs opacity-60 font-normal">AI handles it</span>
              </button>
              <button
                phx-click="triage_defer"
                class="border-2 border-yellow-500 text-yellow-500 py-4 hover:bg-yellow-900 hover:bg-opacity-30 transition-all font-bold text-sm"
              >
                [F] DEFER<br />
                <span class="text-xs opacity-60 font-normal">Revisit tomorrow</span>
              </button>
              <button
                phx-click="triage_skip"
                class="border-2 border-green-500 border-opacity-30 text-green-500 opacity-60 py-4 hover:opacity-100 transition-all font-bold text-sm"
              >
                [S] SKIP<br />
                <span class="text-xs opacity-60 font-normal">Next item</span>
              </button>
            </div>

            <div class="text-center mt-4 text-xs opacity-40">
              Use keyboard: D (deploy) | F (defer) | S (skip)
            </div>
          </div>
        </div>
      <% else %>
        <div class="text-center border-2 border-green-500 p-12">
          <div class="text-2xl mb-4">✓</div>
          <div class="text-lg font-bold mb-2">TRIAGE COMPLETE</div>
          <div class="text-xs opacity-60 mb-6">All signals processed</div>
          <button
            phx-click="switch_mode"
            phx-value-mode="threat"
            class="border border-green-500 px-4 py-2 text-xs hover:bg-green-900 hover:bg-opacity-20"
          >
            [RETURN TO THREAT VIEW]
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  # Signal Card Component - Dynamic sizing based on priority
  attr :signal, :map, required: true

  defp signal_card(assigns) do
    # Size based on priority: critical = large, high = medium, medium = small
    col_span =
      case assigns.signal.severity do
        "CRITICAL" -> "col-span-12 lg:col-span-8"
        "HIGH" -> "col-span-12 lg:col-span-6"
        "ELEVATED" -> "col-span-12 lg:col-span-4"
        _ -> "col-span-12 lg:col-span-3"
      end

    assigns = assign(assigns, :col_span, col_span)

    ~H"""
    <div class={[
      @col_span,
      "border-2 p-3 transition-all hover:scale-[1.02]",
      signal_severity_border(@signal.severity)
    ]}>
      <div class="flex items-start justify-between gap-2 mb-2">
        <div class="flex-1">
          <div class={[
            "text-xs font-bold mb-1",
            signal_severity_text(@signal.severity)
          ]}>
            <%= @signal.severity %> | <%= @signal.domain %>
          </div>
          <div class="text-sm font-bold mb-2">
            <%= @signal.title %>
          </div>
          <div class="text-xs opacity-70 mb-2">
            <%= @signal.description %>
          </div>
        </div>
        <span class={["text-lg", velocity_color(@signal.velocity)]}>
          <%= @signal.velocity_symbol %>
        </span>
      </div>

      <div class="text-xs opacity-60 space-y-1 mb-3">
        <div>IMPACT: <%= @signal.impact %></div>
        <div>AGE: <%= @signal.age %></div>
      </div>

      <div class="flex gap-1">
        <button
          phx-click="signal_action"
          phx-value-id={@signal.id}
          phx-value-action="deploy"
          class="flex-1 border border-green-500 px-2 py-1 text-[10px] hover:bg-green-900 hover:bg-opacity-20"
        >
          DEPLOY
        </button>
        <button
          phx-click="signal_action"
          phx-value-id={@signal.id}
          phx-value-action="defer"
          class="border border-yellow-500 text-yellow-500 px-2 py-1 text-[10px] hover:bg-yellow-900 hover:bg-opacity-20"
        >
          DEFER
        </button>
      </div>
    </div>
    """
  end

  # Domain Pulse Card
  attr :domain, :map, required: true

  defp domain_pulse_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 p-4">
      <div class="flex items-center justify-between mb-4">
        <div class="text-sm font-bold"><%= @domain.name %></div>
        <span class={health_class(@domain.health)}>{health_symbol(@domain.health)}</span>
      </div>

      <div class="grid grid-cols-2 gap-4 text-xs mb-4">
        <div>
          <div class="opacity-60 mb-1">ACTIVE</div>
          <div class="text-lg font-bold"><%= @domain.active %></div>
        </div>
        <div>
          <div class="opacity-60 mb-1">PENDING</div>
          <div class="text-lg font-bold"><%= @domain.pending %></div>
        </div>
      </div>

      <div class="border-t border-green-500 border-opacity-30 pt-3">
        <div class={[
          "text-xs flex items-center gap-2",
          velocity_text_class(@domain.velocity)
        ]}>
          <span class="text-base"><%= @domain.velocity_symbol %></span>
          <span><%= @domain.velocity_text %></span>
        </div>
      </div>
    </div>
    """
  end

  # Helper Functions

  defp assign_signals(socket, user_id) do
    # Load commands from database
    commands =
      from(c in UserCommand,
        where: c.user_id == ^user_id and c.status == "pending",
        order_by: [
          desc:
            fragment(
              "CASE ? WHEN 'critical' THEN 4 WHEN 'high' THEN 3 WHEN 'medium' THEN 2 WHEN 'low' THEN 1 ELSE 0 END",
              c.urgency
            ),
          desc: c.inserted_at
        ]
      )
      |> Repo.all()

    # Convert commands to signals format
    signals =
      commands
      |> Enum.with_index(1)
      |> Enum.map(fn {cmd, idx} ->
        command_to_signal(cmd, idx)
      end)

    assign(socket, :signals, signals)
  end

  defp command_to_signal(command, id) do
    severity = urgency_to_severity(command.urgency)
    priority = urgency_to_priority(command.urgency)
    age = calculate_age(command.inserted_at)

    %{
      id: id,
      command_id: command.id,
      severity: severity,
      domain: extract_domain(command.command_text),
      title: String.slice(command.command_text, 0, 60),
      description: command.llm_reasoning || command.command_text,
      impact: "Business",
      age: age,
      priority: priority,
      velocity: "stable",
      velocity_symbol: "→"
    }
  end

  defp urgency_to_severity(urgency) do
    case urgency do
      "critical" -> "CRITICAL"
      "high" -> "HIGH"
      "medium" -> "ELEVATED"
      "low" -> "MEDIUM"
      _ -> "MEDIUM"
    end
  end

  defp urgency_to_priority(urgency) do
    case urgency do
      "critical" -> 100
      "high" -> 80
      "medium" -> 60
      "low" -> 40
      _ -> 50
    end
  end

  defp extract_domain(command_text) do
    text_lower = String.downcase(command_text)

    cond do
      String.contains?(text_lower, ["homepage", "website", "landing", "copy"]) -> "Website"
      String.contains?(text_lower, ["code", "bug", "sql", "security", "api"]) -> "App"
      String.contains?(text_lower, ["customer", "support", "ticket"]) -> "Customers"
      String.contains?(text_lower, ["sales", "deal", "enterprise"]) -> "Sales"
      String.contains?(text_lower, ["marketing", "campaign", "email"]) -> "Marketing"
      String.contains?(text_lower, ["hr", "hiring", "job"]) -> "HR"
      true -> "General"
    end
  end

  defp calculate_age(inserted_at) do
    if inserted_at do
      diff = DateTime.diff(DateTime.utc_now(), inserted_at, :second)

      cond do
        diff < 3600 -> "#{div(diff, 60)}m"
        diff < 86400 -> "#{div(diff, 3600)}h"
        true -> "#{div(diff, 86400)}d"
      end
    else
      "0m"
    end
  end

  defp assign_domain_pulse(socket) do
    pulse = [
      %{
        name: "Sales",
        health: "critical",
        active: 7,
        pending: 12,
        velocity: "declining",
        velocity_symbol: "↗",
        velocity_text: "Pipeline velocity slowing"
      },
      %{
        name: "App",
        health: "warning",
        active: 3,
        pending: 8,
        velocity: "stable",
        velocity_symbol: "→",
        velocity_text: "Steady state"
      },
      %{
        name: "Marketing",
        health: "warning",
        active: 2,
        pending: 5,
        velocity: "improving",
        velocity_symbol: "↘",
        velocity_text: "Performance improving"
      },
      %{
        name: "Customers",
        health: "healthy",
        active: 4,
        pending: 6,
        velocity: "improving",
        velocity_symbol: "↘",
        velocity_text: "Response time decreasing"
      },
      %{
        name: "Website",
        health: "healthy",
        active: 1,
        pending: 3,
        velocity: "stable",
        velocity_symbol: "→",
        velocity_text: "Normal operations"
      },
      %{
        name: "HR",
        health: "healthy",
        active: 1,
        pending: 2,
        velocity: "stable",
        velocity_symbol: "→",
        velocity_text: "On track"
      }
    ]

    assign(socket, :domain_pulse, pulse)
  end

  defp update_domain_pulse(socket) do
    # Simulate pulse updates (would be real data)
    socket
  end

  defp advance_triage(socket) do
    Phoenix.Component.update(socket, :triage_index, &(&1 + 1))
  end

  defp remove_current_signal(socket) do
    index = socket.assigns.triage_index
    signals = socket.assigns.signals

    if index < length(signals) do
      new_signals = List.delete_at(signals, index)
      assign(socket, :signals, new_signals)
    else
      socket
    end
  end

  defp remove_signal(socket, id) do
    signals = Enum.reject(socket.assigns.signals, fn s -> s.id == id end)
    assign(socket, :signals, signals)
  end

  defp critical_count(signals) do
    Enum.count(signals, fn s -> s.severity == "CRITICAL" end)
  end

  defp escalating_count(signals) do
    Enum.count(signals, fn s -> s.velocity == "escalating" end)
  end

  defp improving_count(signals) do
    Enum.count(signals, fn s -> s.velocity == "improving" end)
  end

  defp ops_active_count, do: 4

  defp mode_button_class(current_mode, mode) do
    base = "px-3 py-1 border transition-all"

    if current_mode == mode do
      base <> " border-green-400 text-green-400 bg-green-900 bg-opacity-20"
    else
      base <> " border-green-500 border-opacity-30 opacity-60 hover:opacity-100"
    end
  end

  defp signal_severity_border(severity) do
    case severity do
      "CRITICAL" -> "border-red-500"
      "HIGH" -> "border-yellow-500"
      "ELEVATED" -> "border-orange-500"
      "MEDIUM" -> "border-green-500 border-opacity-50"
      _ -> "border-green-500 border-opacity-30"
    end
  end

  defp signal_severity_text(severity) do
    case severity do
      "CRITICAL" -> "text-red-500"
      "HIGH" -> "text-yellow-500"
      "ELEVATED" -> "text-orange-500"
      _ -> "text-green-500"
    end
  end

  defp velocity_color(velocity) do
    case velocity do
      "escalating" -> "text-red-500"
      "improving" -> "text-green-400"
      _ -> "text-green-500 opacity-60"
    end
  end

  defp velocity_text_class(velocity) do
    case velocity do
      "declining" -> "text-red-500"
      "improving" -> "text-green-400"
      _ -> "text-green-500 opacity-60"
    end
  end

  defp health_class(health) do
    case health do
      "healthy" -> "text-green-400"
      "warning" -> "text-yellow-500"
      "critical" -> "text-red-500"
      _ -> "text-green-500"
    end
  end

  defp health_symbol(health) do
    case health do
      "healthy" -> "●"
      "warning" -> "▲"
      "critical" -> "✕"
      _ -> "○"
    end
  end
end
