defmodule ShepherdWeb.HqLive.Index2 do
  use ShepherdWeb, :live_view
  import Ecto.Query, except: [update: 3]
  alias Shepherd.Commands.Command
  alias Shepherd.LLM.{CommandManager, FeedbackManager}
  alias Shepherd.Repo

  @impl true
  def mount(_params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    if connected?(socket) do
      :timer.send_interval(1000, self(), :tick)
    end

    socket =
      socket
      |> assign(:page_title, "HQ v2")
      |> assign(:active_section, "hq")
      |> assign(:user_id, user_id)
      |> assign(:notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(user_id))
      |> assign(:command_input, "")
      |> assign_threats()
      |> assign_active_operations()
      |> assign_command_queue()
      |> assign_domain_status()
      |> assign_stats()

    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    socket =
      socket
      |> update_active_operations()

    {:noreply, socket}
  end

  @impl true
  def handle_event("deploy_threat", %{"id" => id}, socket) do
    socket =
      socket
      |> remove_threat(id)
      |> add_flash_message(:info, "AI resources deployed to threat ##{id}")

    {:noreply, socket}
  end

  @impl true
  def handle_event("defer_threat", %{"id" => id}, socket) do
    socket =
      socket
      |> remove_threat(id)
      |> add_flash_message(:info, "Threat ##{id} deferred to tomorrow")

    {:noreply, socket}
  end

  @impl true
  def handle_event("dismiss_threat", %{"id" => id}, socket) do
    socket =
      socket
      |> remove_threat(id)
      |> add_flash_message(:info, "Threat ##{id} dismissed")

    {:noreply, socket}
  end

  @impl true
  def handle_event("abort_operation", %{"name" => name}, socket) do
    socket =
      socket
      |> remove_operation(name)
      |> add_flash_message(:warning, "Operation #{name} aborted")

    {:noreply, socket}
  end

  @impl true
  def handle_event("bump_queue", %{"index" => index_str}, socket) do
    case Integer.parse(index_str) do
      {index, _} ->
        queue = socket.assigns.command_queue

        if index > 0 and index < length(queue) do
          item = Enum.at(queue, index)
          new_queue = List.delete_at(queue, index) |> List.insert_at(0, item)

          socket =
            socket
            |> assign(:command_queue, new_queue)
            |> add_flash_message(:info, "Command bumped to front of queue")

          {:noreply, socket}
        else
          {:noreply, socket}
        end

      :error ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("kill_queue", %{"index" => index_str}, socket) do
    case Integer.parse(index_str) do
      {index, _} ->
        queue = socket.assigns.command_queue

        if index >= 0 and index < length(queue) do
          new_queue = List.delete_at(queue, index)

          socket =
            socket
            |> assign(:command_queue, new_queue)
            |> add_flash_message(:warning, "Command removed from queue")

          {:noreply, socket}
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
      domain = detect_domain(trimmed)

      attrs = %{
        user_id: user_id,
        command_text: trimmed,
        urgency: "medium",
        status: "pending",
        created_by: "user",
        entity_type: String.downcase(domain)
      }

      case CommandManager.create_command(attrs) do
        {:ok, cmd} ->
          new_queue_item = %{
            id: cmd.id,
            text: cmd.command_text,
            domain: cmd.entity_type,
            eta: "~#{estimate_eta(cmd.urgency)}m"
          }

          socket =
            socket
            |> update(:command_queue, fn queue -> queue ++ [new_queue_item] end)
            |> assign(:command_input, "")
            |> add_flash_message(:info, "Command queued for execution")

          {:noreply, socket}

        {:error, _changeset} ->
          {:noreply, socket |> assign(:command_input, "") |> add_flash_message(:error, "Failed to create command")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_command", %{"value" => value}, socket) do
    {:noreply, assign(socket, :command_input, value)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="fixed top-0 right-0 bottom-0 left-16 md:left-40 bg-terminal text-green-500 overflow-hidden terminal-screen flex flex-col">
      <!-- CRT Scanlines Effect -->
      <div class="scanlines pointer-events-none"></div>

      <!-- SITREP Header -->
      <div class="border-b-2 border-green-500 p-3 relative">
        <div class="flex items-center justify-between mb-2">
          <div class="flex items-center gap-4">
            <div class="text-sm lg:text-base font-bold uppercase">HQ - COMMAND OPERATIONS</div>
            <div class="text-xs opacity-60">
              [<.link navigate="/" class="hover:text-green-300">HQ v1</.link> | <span class="text-green-400">HQ v2</span>]
            </div>
          </div>
          <div class="flex items-center gap-3">
            <div class={[
              "text-xs font-bold px-2 py-1 border-2",
              defcon_class(@defcon_level)
            ]}>
              DEFCON <%= @defcon_level %>
            </div>
            <div class="text-xs opacity-80">
              OPS: <%= @active_ops_count %> | QUEUE: <%= @queue_depth %>
            </div>
          </div>
        </div>
      </div>

      <!-- Main Layout -->
      <div class="flex flex-1 overflow-hidden">
        <!-- Left: THREAT BOARD -->
        <div class="w-80 flex-shrink-0 border-r-2 border-green-500 overflow-auto relative">
          <div class="border-b-2 border-red-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-red-500">⊗ THREAT BOARD</span>
          </div>
          <div class="p-3 space-y-2">
            <%= if @threats == [] do %>
              <div class="text-center text-xs opacity-60 py-8 border border-green-500">
                ALL CLEAR<br />NO ACTIVE THREATS
              </div>
            <% else %>
              <%= for threat <- @threats do %>
                <.threat_card threat={threat} />
              <% end %>
            <% end %>
          </div>
        </div>

        <!-- Center: ACTIVE OPS + COMMAND QUEUE -->
        <div class="flex-1 flex flex-col overflow-hidden">
          <!-- Active Operations -->
          <div class="border-b-2 border-green-500 flex-1 overflow-auto relative">
            <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal sticky top-0 z-10">
              <span class="text-sm font-bold text-green-400">═══ ACTIVE OPERATIONS ═══</span>
            </div>
            <div class="p-3 space-y-3">
              <%= if @active_operations == [] do %>
                <div class="text-center text-xs opacity-60 py-8">
                  NO ACTIVE OPERATIONS
                </div>
              <% else %>
                <%= for op <- @active_operations do %>
                  <.operation_card operation={op} />
                <% end %>
              <% end %>
            </div>
          </div>

          <!-- Command Queue -->
          <div class="h-64 border-b-2 border-green-500 overflow-auto relative">
            <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal sticky top-0 z-10">
              <span class="text-sm font-bold text-green-400">═══ COMMAND QUEUE ═══</span>
            </div>
            <div class="p-3 space-y-2">
              <%= if @command_queue == [] do %>
                <div class="text-center text-xs opacity-60 py-4">
                  QUEUE EMPTY
                </div>
              <% else %>
                <%= for {cmd, index} <- Enum.with_index(@command_queue) do %>
                  <.queue_item command={cmd} index={index} position={index + 1} />
                <% end %>
              <% end %>
            </div>
          </div>

          <!-- Command Input -->
          <div class="border-t-2 border-green-500 p-3 bg-terminal">
            <form phx-submit="submit_command" class="flex gap-2">
              <div class="flex-1 flex items-center border-2 border-green-500 bg-terminal px-3 py-2">
                <span class="text-green-400 mr-2">></span>
                <input
                  type="text"
                  name="command"
                  value={@command_input}
                  phx-change="update_command"
                  placeholder="Issue Command..."
                  class="flex-1 bg-transparent outline-none text-green-500 placeholder-green-500 placeholder-opacity-40"
                  autocomplete="off"
                />
              </div>
              <button
                type="submit"
                class="border-2 border-green-500 text-green-500 px-6 py-2 hover:bg-green-900 hover:bg-opacity-30 hover:text-green-400 hover:border-green-400 transition-all font-bold uppercase text-xs"
              >
                [EXECUTE]
              </button>
            </form>
          </div>
        </div>

        <!-- Right: DOMAIN STATUS -->
        <div class="w-64 flex-shrink-0 border-l-2 border-green-500 overflow-auto relative">
          <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
            <span class="text-sm font-bold text-green-400">DOMAINS</span>
          </div>
          <div class="p-3 space-y-2">
            <%= for domain <- @domain_status do %>
              <.domain_status_card domain={domain} />
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Threat Card Component
  attr :threat, :map, required: true

  defp threat_card(assigns) do
    ~H"""
    <div class={[
      "border-2 bg-terminal p-2 text-xs",
      threat_border_class(@threat.severity)
    ]}>
      <div class="flex items-start justify-between gap-2 mb-2">
        <div class="flex-1">
          <div class={[
            "font-bold uppercase mb-1",
            threat_text_class(@threat.severity)
          ]}>
            <%= @threat.severity %> | <%= @threat.domain %>
          </div>
          <div class="opacity-90 mb-2">
            <%= @threat.title %>
          </div>
          <div class="opacity-60 space-y-0.5">
            <div>IMPACT: <%= @threat.impact %></div>
            <div>TIME: <%= @threat.time_detected %></div>
          </div>
        </div>
      </div>
      <div class="flex gap-1 justify-end mt-2">
        <button
          phx-click="deploy_threat"
          phx-value-id={@threat.id}
          class="border border-green-500 text-green-500 px-2 py-1 hover:bg-green-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [DEPLOY]
        </button>
        <button
          phx-click="defer_threat"
          phx-value-id={@threat.id}
          class="border border-yellow-500 text-yellow-500 px-2 py-1 hover:bg-yellow-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [DEFER]
        </button>
        <button
          phx-click="dismiss_threat"
          phx-value-id={@threat.id}
          class="border border-red-500 text-red-500 px-2 py-1 hover:bg-red-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [DISMISS]
        </button>
      </div>
    </div>
    """
  end

  # Operation Card Component
  attr :operation, :map, required: true

  defp operation_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal p-3">
      <div class="flex items-start justify-between mb-2">
        <div class="flex-1">
          <div class="text-sm font-bold mb-1"><%= @operation.name %></div>
          <div class="text-xs opacity-80 mb-2"><%= @operation.description %></div>
          <div class="text-xs opacity-60">
            DOMAIN: <%= @operation.domain %> | AGENT: <%= @operation.agent %>
          </div>
        </div>
        <button
          phx-click="abort_operation"
          phx-value-name={@operation.name}
          class="border border-red-500 text-red-500 px-2 py-1 hover:bg-red-900 hover:bg-opacity-20 uppercase text-[10px] ml-2"
        >
          [ABORT]
        </button>
      </div>
      <div class="flex items-center gap-2 text-xs">
        <div class="flex-1">
          [<%= render_bar(@operation.progress, 20) %>]
        </div>
        <span><%= @operation.progress %>%</span>
        <span class="opacity-60">ETA: <%= @operation.eta %></span>
      </div>
    </div>
    """
  end

  # Queue Item Component
  attr :command, :map, required: true
  attr :index, :integer, required: true
  attr :position, :integer, required: true

  defp queue_item(assigns) do
    ~H"""
    <div class="border border-green-500 bg-terminal p-2 flex items-center gap-2 text-xs">
      <div class="text-green-400 font-bold w-8">#<%= @position %></div>
      <div class="flex-1">
        <div class="font-bold mb-1"><%= @command.text %></div>
        <div class="opacity-60">DOMAIN: <%= @command.domain %> | ETA: <%= @command.eta %></div>
      </div>
      <div class="flex gap-1">
        <%= if @index > 0 do %>
          <button
            phx-click="bump_queue"
            phx-value-index={@index}
            class="border border-yellow-500 text-yellow-500 px-2 py-1 hover:bg-yellow-900 hover:bg-opacity-20 uppercase text-[10px]"
          >
            [BUMP]
          </button>
        <% end %>
        <button
          phx-click="kill_queue"
          phx-value-index={@index}
          class="border border-red-500 text-red-500 px-2 py-1 hover:bg-red-900 hover:bg-opacity-20 uppercase text-[10px]"
        >
          [KILL]
        </button>
      </div>
    </div>
    """
  end

  # Domain Status Card Component
  attr :domain, :map, required: true

  defp domain_status_card(assigns) do
    ~H"""
    <div class="border border-green-500 bg-terminal p-2 text-xs">
      <div class="flex items-center justify-between mb-2">
        <div class="font-bold uppercase"><%= @domain.name %></div>
        <span class={domain_health_class(@domain.health)}>
          <%= health_symbol(@domain.health) %>
        </span>
      </div>
      <div class="opacity-80 space-y-0.5">
        <div>PENDING: <%= @domain.pending %></div>
        <div>LAST: <%= @domain.last_activity %></div>
      </div>
      <.link
        navigate={@domain.link}
        class="block text-center border border-green-500 py-1 mt-2 hover:bg-green-900 hover:bg-opacity-20 uppercase text-[10px]"
      >
        [INTERVENE]
      </.link>
    </div>
    """
  end

  # Helper Functions

  defp assign_threats(socket) do
    user_id = socket.assigns.user_id

    threats =
      FeedbackManager.get_active_feedback(user_id)
      |> Enum.map(fn feedback ->
        %{
          id: feedback.id,
          severity: map_severity(feedback.severity),
          domain: feedback.feedback_type,
          title: feedback.title,
          impact: feedback.severity,
          time_detected: format_time_ago(feedback.inserted_at)
        }
      end)

    assign(socket, :threats, threats)
  end

  defp map_severity("critical"), do: "CRITICAL"
  defp map_severity("warning"), do: "HIGH"
  defp map_severity(_), do: "MEDIUM"

  defp format_time_ago(datetime) do
    diff = DateTime.diff(DateTime.utc_now(), datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> "#{div(diff, 86400)}d ago"
    end
  end

  defp assign_active_operations(socket) do
    user_id = socket.assigns.user_id

    commands =
      from(c in Command,
        where: c.user_id == ^user_id and c.status == "pending",
        order_by: [desc: c.inserted_at],
        limit: 5
      )
      |> Repo.all()

    operations =
      Enum.map(commands, fn command ->
        %{
          name: String.slice(command.command_text, 0, 40),
          description: command.llm_reasoning || command.command_text,
          domain: command.entity_type,
          agent: "AI_AGENT",
          progress: 0,
          eta: "--:--"
        }
      end)

    assign(socket, :active_operations, operations)
  end

  defp assign_command_queue(socket) do
    user_id = socket.assigns.user_id

    commands =
      from(c in Command,
        where: c.user_id == ^user_id and c.status == "pending",
        order_by: [desc: c.inserted_at],
        offset: 5,
        limit: 20
      )
      |> Repo.all()

    queue =
      Enum.map(commands, fn command ->
        %{
          id: command.id,
          text: command.command_text,
          domain: command.entity_type,
          eta: "~#{estimate_eta(command.urgency)}m"
        }
      end)

    assign(socket, :command_queue, queue)
  end

  defp estimate_eta("critical"), do: 5
  defp estimate_eta("high"), do: 10
  defp estimate_eta("medium"), do: 15
  defp estimate_eta(_), do: 20

  defp assign_domain_status(socket) do
    user_id = socket.assigns.user_id

    counts_by_type =
      from(c in Command,
        where: c.user_id == ^user_id and c.status == "pending",
        group_by: c.entity_type,
        select: {c.entity_type, count(c.id)}
      )
      |> Repo.all()
      |> Map.new()

    known_domains = [
      %{name: "Website", entity_type: "website", link: "/website"},
      %{name: "App", entity_type: "app", link: "/app"},
      %{name: "Marketing", entity_type: "marketing", link: "/marketing"},
      %{name: "Funnel", entity_type: "funnel", link: "/funnel"},
      %{name: "Sales", entity_type: "sales", link: "/sales"},
      %{name: "HR", entity_type: "hr", link: "/hr"},
      %{name: "Customers", entity_type: "customers", link: "/customers"}
    ]

    domains =
      Enum.map(known_domains, fn d ->
        pending = Map.get(counts_by_type, d.entity_type, 0)

        health =
          cond do
            pending >= 7 -> "critical"
            pending >= 3 -> "warning"
            true -> "healthy"
          end

        %{
          name: d.name,
          health: health,
          pending: pending,
          last_activity: "N/A",
          link: d.link
        }
      end)

    assign(socket, :domain_status, domains)
  end

  defp assign_stats(socket) do
    threats = socket.assigns.threats
    ops = socket.assigns.active_operations
    queue = socket.assigns.command_queue

    active_ops_count = length(ops)
    queue_depth = length(queue)

    critical_count = Enum.count(threats, fn t -> t.severity == "CRITICAL" end)

    defcon_level =
      cond do
        critical_count >= 3 -> 1
        critical_count >= 1 -> 2
        length(threats) > 0 -> 3
        true -> 4
      end

    socket
    |> assign(:defcon_level, defcon_level)
    |> assign(:active_ops_count, active_ops_count)
    |> assign(:queue_depth, queue_depth)
  end

  defp update_active_operations(socket) do
    updated_ops =
      Enum.map(socket.assigns.active_operations, fn op ->
        new_progress = min(op.progress + Enum.random(1..3), 100)
        %{op | progress: new_progress}
      end)

    assign(socket, :active_operations, updated_ops)
  end

  defp remove_threat(socket, id) do
    threats = Enum.reject(socket.assigns.threats, fn t -> to_string(t.id) == to_string(id) end)
    assign(socket, :threats, threats)
  end

  defp remove_operation(socket, name) do
    operations = Enum.reject(socket.assigns.active_operations, fn op -> op.name == name end)
    assign(socket, :active_operations, operations)
  end

  defp add_flash_message(socket, type, message) do
    Phoenix.LiveView.put_flash(socket, type, message)
  end

  defp detect_domain(command) do
    cond do
      String.contains?(String.downcase(command), ["email", "campaign", "marketing", "social"]) ->
        "Marketing"

      String.contains?(String.downcase(command), ["deal", "sales", "pricing", "revenue"]) ->
        "Sales"

      String.contains?(String.downcase(command), ["bug", "fix", "code", "deploy", "api"]) ->
        "App"

      String.contains?(String.downcase(command), ["website", "landing", "page"]) ->
        "Website"

      String.contains?(String.downcase(command), ["customer", "support", "ticket"]) ->
        "Customers"

      String.contains?(String.downcase(command), ["hire", "recruit", "job"]) ->
        "HR"

      true ->
        "General"
    end
  end

  defp defcon_class(level) do
    case level do
      1 -> "border-red-500 text-red-500 animate-pulse"
      2 -> "border-yellow-500 text-yellow-500"
      3 -> "border-green-400 text-green-400"
      _ -> "border-green-500 text-green-500"
    end
  end

  defp threat_border_class(severity) do
    case severity do
      "CRITICAL" -> "border-red-500"
      "HIGH" -> "border-yellow-500"
      "ELEVATED" -> "border-orange-500"
      _ -> "border-green-500"
    end
  end

  defp threat_text_class(severity) do
    case severity do
      "CRITICAL" -> "text-red-500"
      "HIGH" -> "text-yellow-500"
      "ELEVATED" -> "text-orange-500"
      _ -> "text-green-500"
    end
  end

  defp domain_health_class(health) do
    case health do
      "healthy" -> "text-green-400"
      "warning" -> "text-yellow-500"
      "critical" -> "text-red-500 animate-pulse"
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

  defp render_bar(percentage, width) do
    filled = round(percentage / 100 * width)
    empty = width - filled

    String.duplicate("█", filled) <> String.duplicate("░", empty)
  end
end
