defmodule ShepherdWeb.WebsiteLive.Index do
  use ShepherdWeb, :live_view
  alias Shepherd.LLM.{WebsiteManager, DirectiveProcessor, CommandManager}
  alias Shepherd.Repo
  alias Shepherd.Websites.Website
  import Ecto.Query

  @impl true
  def mount(params, _session, socket) do
    user_id = socket.assigns.current_scope.user.id

    # Fetch the first website for this user
    website = Repo.one(from w in Website, where: w.user_id == ^user_id, limit: 1)

    # Fetch onboarding questions if website exists
    questions =
      if website do
        case WebsiteManager.get_unanswered_questions_by_type(user_id, "website", website.id, "onboarding") do
          {:ok, questions} -> questions
          {:error, _} -> []
        end
      else
        []
      end

    # Fetch complaints if website exists
    complaints =
      if website do
        case WebsiteManager.get_unanswered_questions_by_type(user_id, "website", website.id, "complaint") do
          {:ok, complaints} -> complaints
          {:error, _} -> []
        end
      else
        []
      end

    # Fetch commands if website exists
    commands =
      if website do
        {:ok, commands} = CommandManager.get_pending_commands(user_id, "website", website.id)
        commands
      else
        []
      end

    # Fetch context if website exists
    context =
      if website do
        case WebsiteManager.get_context(user_id, website.id) do
          {:ok, context} -> context
          {:error, _} -> %{}
        end
      else
        %{}
      end

    socket =
      socket
      |> assign(:page_title, "Website")
      |> assign(:active_section, "website")
      |> assign(:active_tab, params["tab"])
      |> assign(:user_id, user_id)
      |> assign(:notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(user_id))
      |> assign(:website, website)
      |> assign(:questions, questions)
      |> assign(:complaints, complaints)
      |> assign(:commands, commands)
      |> assign(:context, context)

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
        <.website_sidebar active_tab={@active_tab} />
      </div>

      <div class="flex-1 overflow-auto relative">
        <%= case @active_tab do %>
          <% "commands" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow md:hidden">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Commands ═══</span>
                </div>
              </div>

              <%= if @website do %>
                <%= if @context["concept"] && @context["concept"] != "" do %>
                  <div class="mb-6 border-2 border-green-500 terminal-glow p-4">
                    <h3 class="text-xs font-bold text-green-400 uppercase mb-2">Website Concept</h3>
                    <p class="text-xs opacity-80">{@context["concept"]}</p>
                  </div>
                <% end %>

                <%= if Enum.empty?(@commands) do %>
                  <div class="text-center border-2 border-green-500 terminal-glow p-8">
                    <div class="text-4xl mb-4">✓</div>
                    <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                      No pending commands
                    </h3>
                    <p class="text-xs opacity-60">
                      All commands have been completed
                    </p>
                  </div>
                <% else %>
                  <div class="space-y-3 max-w-3xl">
                    <%= for command <- @commands do %>
                      <.command_card command={command} />
                    <% end %>
                  </div>
                <% end %>
              <% else %>
                <div class="text-center border-2 border-green-500 terminal-glow p-8">
                  <div class="text-4xl mb-4">!</div>
                  <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                    No website found
                  </h3>
                  <p class="text-xs opacity-60">
                    Add a website to get started
                  </p>
                </div>
              <% end %>
            </div>
          <% "complain" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow md:hidden">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Complain ═══</span>
                </div>
              </div>

              <%= if @website do %>
                <%= if Enum.empty?(@complaints) do %>
                  <div class="text-center border-2 border-green-500 terminal-glow p-8">
                    <div class="text-4xl mb-4">✓</div>
                    <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                      No active issues detected
                    </h3>
                    <p class="text-xs opacity-60">
                      System is monitoring your website for potential problems
                    </p>
                  </div>
                <% else %>
                  <div class="space-y-3 max-w-3xl">
                    <%= for complaint <- @complaints do %>
                      <.complaint_card complaint={complaint} />
                    <% end %>
                  </div>
                <% end %>
              <% else %>
                <div class="text-center border-2 border-green-500 terminal-glow p-8">
                  <div class="text-4xl mb-4">!</div>
                  <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                    No website found
                  </h3>
                  <p class="text-xs opacity-60">
                    Add a website to track issues
                  </p>
                </div>
              <% end %>
            </div>
          <% "report" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow md:hidden">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Report ═══</span>
                </div>
              </div>

              <%= if @context["concept"] && @context["concept"] != "" do %>
                <div class="space-y-4 max-w-3xl">
                  <div class="border-2 border-green-500 terminal-glow">
                    <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                      <h3 class="text-xs font-bold text-green-400 uppercase">Website Analysis Report</h3>
                    </div>
                    <div class="p-4 space-y-3 text-xs">
                      <%= if @context["concept"] do %>
                        <div class="flex gap-3">
                          <span class="text-green-400 uppercase w-36 flex-shrink-0">Concept:</span>
                          <span class="opacity-80">{@context["concept"]}</span>
                        </div>
                      <% end %>
                      <%= if @context["business_type"] do %>
                        <div class="flex gap-3">
                          <span class="text-green-400 uppercase w-36 flex-shrink-0">Business Type:</span>
                          <span class="opacity-80">{@context["business_type"]}</span>
                        </div>
                      <% end %>
                      <%= if @context["primary_cta"] do %>
                        <div class="flex gap-3">
                          <span class="text-green-400 uppercase w-36 flex-shrink-0">Primary CTA:</span>
                          <span class="opacity-80">{@context["primary_cta"]}</span>
                        </div>
                      <% end %>
                      <%= if @context["conversion_goal"] do %>
                        <div class="flex gap-3">
                          <span class="text-green-400 uppercase w-36 flex-shrink-0">Conversion Goal:</span>
                          <span class="opacity-80">{@context["conversion_goal"]}</span>
                        </div>
                      <% end %>
                    </div>
                  </div>

                  <%= if @context["bottleneck_step"] || @context["bottleneck_issue"] do %>
                    <div class="border-2 border-red-500">
                      <div class="border-b-2 border-red-500 px-4 py-2 bg-terminal">
                        <h3 class="text-xs font-bold text-red-400 uppercase">Bottleneck Identified</h3>
                      </div>
                      <div class="p-4 space-y-3 text-xs">
                        <%= if @context["bottleneck_step"] do %>
                          <div class="flex gap-3">
                            <span class="text-red-400 uppercase w-36 flex-shrink-0">Failing Step:</span>
                            <span class="opacity-80">{@context["bottleneck_step"]}</span>
                          </div>
                        <% end %>
                        <%= if @context["bottleneck_issue"] do %>
                          <div class="flex gap-3">
                            <span class="text-red-400 uppercase w-36 flex-shrink-0">Why It Fails:</span>
                            <span class="opacity-80">{@context["bottleneck_issue"]}</span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <%= if not Enum.empty?(@commands) do %>
                    <div class="border-2 border-green-500 terminal-glow">
                      <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                        <h3 class="text-xs font-bold text-green-400 uppercase">
                          Pending Commands ({length(@commands)})
                        </h3>
                      </div>
                      <div class="p-4 space-y-2">
                        <%= for command <- @commands do %>
                          <div class="flex items-start gap-3 text-xs border-b border-green-500 border-opacity-20 pb-2 last:border-0 last:pb-0">
                            <span class={[
                              "px-1.5 py-0.5 border uppercase font-bold flex-shrink-0",
                              urgency_class(command.urgency)
                            ]}>
                              {command.urgency}
                            </span>
                            <span class="opacity-80">{command.command_text}</span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center border-2 border-green-500 terminal-glow p-8 max-w-3xl">
                  <div class="text-4xl mb-4">◈</div>
                  <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                    No Report Available
                  </h3>
                  <p class="text-xs opacity-60">
                    Run website analysis first to see your report.
                  </p>
                </div>
              <% end %>
            </div>
          <% "brainstorm" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow md:hidden">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Brainstorm ═══</span>
                </div>
              </div>

              <%= if @context["step_analysis"] do %>
                <div class="space-y-4 max-w-3xl">
                  <div class="border-2 border-green-500 terminal-glow">
                    <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                      <h3 class="text-xs font-bold text-green-400 uppercase">
                        8-Step Conversion Ladder Analysis
                      </h3>
                    </div>
                    <div class="divide-y divide-green-500 divide-opacity-20">
                      <%= for {key, label} <- [
                        {"step_1_attention", "Step 1: Attention"},
                        {"step_2_engagement", "Step 2: Engagement"},
                        {"step_3_comprehension", "Step 3: Comprehension"},
                        {"step_4_belief", "Step 4: Belief"},
                        {"step_5_desire", "Step 5: Desire"},
                        {"step_6_urgency", "Step 6: Urgency"},
                        {"step_7_intent", "Step 7: Intent"},
                        {"step_8_action", "Step 8: Action"}
                      ] do %>
                        <%= if Map.get(@context["step_analysis"], key) do %>
                          <% step = @context["step_analysis"][key] %>
                          <% is_bottleneck = @context["bottleneck_step"] && String.contains?(String.downcase(@context["bottleneck_step"] || ""), String.downcase(label)) %>
                          <div class={[
                            "p-4",
                            is_bottleneck && "bg-red-500 bg-opacity-5"
                          ]}>
                            <div class="flex items-center gap-3 mb-1">
                              <span class="text-xs font-bold text-green-400 uppercase">{label}</span>
                              <%= if step["status"] do %>
                                <span class={[
                                  "text-xs px-2 py-0.5 border uppercase font-bold",
                                  step["status"] == "good" && "border-green-500 text-green-500",
                                  step["status"] == "weak" && "border-yellow-500 text-yellow-500",
                                  step["status"] == "failing" && "border-red-500 text-red-500"
                                ]}>
                                  {step["status"]}
                                </span>
                              <% end %>
                              <%= if is_bottleneck do %>
                                <span class="text-xs border border-red-500 text-red-400 px-2 py-0.5 uppercase">
                                  Bottleneck
                                </span>
                              <% end %>
                            </div>
                            <%= if step["notes"] do %>
                              <p class="text-xs opacity-70">{step["notes"]}</p>
                            <% end %>
                          </div>
                        <% end %>
                      <% end %>
                    </div>
                  </div>

                  <%= if @context["confusion"] && @context["confusion"] != [] do %>
                    <div class="border-2 border-yellow-500">
                      <div class="border-b-2 border-yellow-500 px-4 py-2 bg-terminal">
                        <h3 class="text-xs font-bold text-yellow-400 uppercase">Visitor Confusion Points</h3>
                      </div>
                      <div class="p-4 space-y-2">
                        <%= for item <- @context["confusion"] do %>
                          <div class="flex items-start gap-2 text-xs">
                            <span class="text-yellow-400 flex-shrink-0">▸</span>
                            <span class="opacity-80">{item}</span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>

                  <%= if @context["bottleneck_step"] || @context["bottleneck_issue"] do %>
                    <div class="border-2 border-red-500">
                      <div class="border-b-2 border-red-500 px-4 py-2 bg-terminal">
                        <h3 class="text-xs font-bold text-red-400 uppercase">Primary Bottleneck</h3>
                      </div>
                      <div class="p-4 space-y-2 text-xs">
                        <%= if @context["bottleneck_step"] do %>
                          <div class="flex gap-3">
                            <span class="text-red-400 uppercase w-28 flex-shrink-0">Failing Step:</span>
                            <span class="opacity-80">{@context["bottleneck_step"]}</span>
                          </div>
                        <% end %>
                        <%= if @context["bottleneck_issue"] do %>
                          <div class="flex gap-3">
                            <span class="text-red-400 uppercase w-28 flex-shrink-0">Root Cause:</span>
                            <span class="opacity-80">{@context["bottleneck_issue"]}</span>
                          </div>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% else %>
                <div class="text-center border-2 border-green-500 terminal-glow p-8 max-w-3xl">
                  <div class="text-4xl mb-4">◈</div>
                  <h3 class="text-sm font-bold uppercase text-green-400 mb-2">
                    No Brainstorm Data Available
                  </h3>
                  <p class="text-xs opacity-60">
                    Run website analysis first to brainstorm improvements.
                  </p>
                </div>
              <% end %>
            </div>
          <% "settings" -> %>
            <div class="p-4 lg:p-6">
              <div class="mb-6 border-2 border-green-500 terminal-glow md:hidden">
                <div class="border-b-2 border-green-500 px-3 py-2 bg-terminal">
                  <span class="text-sm font-bold text-green-400 uppercase">═══ Settings ═══</span>
                </div>
              </div>

              <%= if @website do %>
                <div class="max-w-2xl">
                  <form phx-submit="update_domain" class="border-2 border-green-500 terminal-glow">
                    <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                      <h3 class="text-xs font-bold text-green-400 uppercase">Website Domain</h3>
                    </div>
                    <div class="p-4">
                      <div class="mb-4">
                        <label for="domain" class="block text-xs text-green-400 mb-2 uppercase">
                          Domain/URL
                        </label>
                        <input
                          type="text"
                          id="domain"
                          name="domain"
                          value={@website.url}
                          placeholder="https://example.com"
                          class="w-full bg-terminal border border-green-500 text-green-500 px-3 py-2 text-sm focus:outline-none focus:border-green-400 terminal-glow"
                        />
                        <p class="text-xs opacity-60 mt-1">Enter the full URL of your website</p>
                      </div>

                      <div class="flex gap-2">
                        <button
                          type="submit"
                          class="border border-green-500 text-green-500 px-4 py-2 text-xs hover:bg-green-900 hover:bg-opacity-20 hover:border-green-400 uppercase"
                        >
                          [Save Domain]
                        </button>
                      </div>
                    </div>
                  </form>

                  <div class="mt-6 border-2 border-green-500 terminal-glow">
                    <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                      <h3 class="text-xs font-bold text-green-400 uppercase">Website Info</h3>
                    </div>
                    <div class="p-4">
                      <div class="space-y-2 text-xs">
                        <div class="flex">
                          <span class="text-green-400 w-32">Name:</span>
                          <span class="opacity-80">{@website.name || "N/A"}</span>
                        </div>
                        <div class="flex">
                          <span class="text-green-400 w-32">Status:</span>
                          <span class={[
                            "opacity-80",
                            @website.status == "pending_analysis" && "text-yellow-400",
                            @website.status == "analyzing" && "text-yellow-400",
                            @website.status == "analyzed" && "text-green-400"
                          ]}>
                            {@website.status}
                          </span>
                        </div>
                        <div class="flex">
                          <span class="text-green-400 w-32">Last Scanned:</span>
                          <span class="opacity-80">
                            <%= if @website.last_scanned_at do %>
                              {Calendar.strftime(@website.last_scanned_at, "%Y-%m-%d %H:%M")}
                            <% else %>
                              Never
                            <% end %>
                          </span>
                        </div>
                        <div class="flex">
                          <span class="text-green-400 w-32">Created:</span>
                          <span class="opacity-80">
                            {Calendar.strftime(@website.inserted_at, "%Y-%m-%d %H:%M")}
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div class="mt-6 border-2 border-green-500 terminal-glow">
                    <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                      <h3 class="text-xs font-bold text-green-400 uppercase">Website Analysis</h3>
                    </div>
                    <div class="p-4">
                      <p class="text-xs opacity-70 mb-3">
                        Website analysis is performed via Claude Code CLI.
                      </p>
                      <%= if @website.status == "pending_analysis" do %>
                        <div class="border border-yellow-500 bg-yellow-500 bg-opacity-10 p-3">
                          <p class="text-xs text-yellow-400 font-bold mb-2">⚠ Awaiting Analysis (Step 1 of 2)</p>
                          <p class="text-xs opacity-80">
                            Run the analysis script to process this website:
                          </p>
                          <code class="block mt-2 text-xs bg-black bg-opacity-40 p-2 border border-green-500">
                            ./bin/analyze_websites.sh
                          </code>
                        </div>
                      <% end %>

                      <%= if @website.status == "analyzed" do %>
                        <div class="border border-green-400 bg-green-400 bg-opacity-10 p-3">
                          <p class="text-xs text-green-400 font-bold mb-2">✓ Analysis Complete (Step 2 of 2)</p>
                          <p class="text-xs opacity-80 mb-2">
                            Website analyzed successfully. Generate improvement commands:
                          </p>
                          <code class="block text-xs bg-black bg-opacity-40 p-2 border border-green-500">
                            ./bin/generate_commands.sh
                          </code>
                        </div>
                      <% end %>

                      <%= if @website.status == "active" do %>
                        <div class="text-xs space-y-2">
                          <div class="flex">
                            <span class="text-green-400 w-32">Status:</span>
                            <span class="opacity-80">{@website.status}</span>
                          </div>
                          <%= if @website.last_scanned_at do %>
                            <div class="flex">
                              <span class="text-green-400 w-32">Last Analyzed:</span>
                              <span class="opacity-80">
                                {Calendar.strftime(@website.last_scanned_at, "%Y-%m-%d %H:%M")}
                              </span>
                            </div>
                          <% end %>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% else %>
                <div class="max-w-2xl">
                  <form phx-submit="create_website" class="border-2 border-green-500 terminal-glow">
                    <div class="border-b-2 border-green-500 px-4 py-2 bg-terminal">
                      <h3 class="text-xs font-bold text-green-400 uppercase">Add Your Website</h3>
                    </div>
                    <div class="p-4">
                      <div class="mb-4">
                        <label for="url" class="block text-xs text-green-400 mb-2 uppercase">
                          Website URL
                        </label>
                        <input
                          type="text"
                          id="url"
                          name="url"
                          placeholder="https://example.com"
                          class="w-full bg-terminal border border-green-500 text-green-500 px-3 py-2 text-sm focus:outline-none focus:border-green-400 terminal-glow"
                          required
                        />
                      </div>
                      <div class="mb-4">
                        <label for="name" class="block text-xs text-green-400 mb-2 uppercase">
                          Website Name (Optional)
                        </label>
                        <input
                          type="text"
                          id="name"
                          name="name"
                          placeholder="My Awesome Site"
                          class="w-full bg-terminal border border-green-500 text-green-500 px-3 py-2 text-sm focus:outline-none focus:border-green-400 terminal-glow"
                        />
                      </div>
                      <button
                        type="submit"
                        class="border border-green-500 text-green-500 px-4 py-2 text-xs hover:bg-green-900 hover:bg-opacity-20 hover:border-green-400 uppercase"
                      >
                        [Submit Website]
                      </button>
                    </div>
                  </form>
                </div>
              <% end %>
            </div>
          <% nil -> %>
            <div class="flex items-center justify-center min-h-full">
              <div class="text-center border-2 border-green-500 terminal-glow p-8">
                <div class="text-4xl mb-4">◆</div>
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
    {:noreply, push_patch(socket, to: ~p"/website?tab=#{tab}")}
  end

  @impl true
  def handle_event("answer_question", _params, %{assigns: %{website: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Please add a website first")}
  end

  @impl true
  def handle_event("answer_question", %{"question-id" => question_id, "answer" => answer}, socket) do
    user_id = socket.assigns.user_id
    website = socket.assigns.website

    case WebsiteManager.record_answer(user_id, question_id, %{"answer" => answer}) do
      {:ok, answered_question} ->
        # Determine if this was onboarding or complaint based on question_type
        question_type = answered_question.question_type || "onboarding"

        # Only process with LLM for onboarding questions (initial setup)
        # Complaints will have separate directive handling in the future
        result =
          if question_type == "onboarding" do
            DirectiveProcessor.process(:on_question_answered, %{
              user_id: user_id,
              website_id: website.id,
              question: answered_question,
              answer: answer
            })
          else
            DirectiveProcessor.process("question_followup", %{
              question_id: answered_question.id,
              user_id: user_id
            })
          end

        _ = result

        socket =
          socket
          |> reload_questions(user_id, website.id)
          |> reload_complaints(user_id, website.id)
          |> reload_context(user_id, website.id)

        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_website", %{"url" => url} = params, socket) when url != "" do
    user_id = socket.assigns.user_id
    name = Map.get(params, "name", "") |> to_string() |> String.trim()

    attrs = %{
      user_id: user_id,
      url: url,
      name: if(name == "", do: nil, else: name)
    }

    case WebsiteManager.create_website_with_scan(attrs) do
      {:ok, website} ->
        {:noreply, assign(socket, :website, website)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to create website")}
    end
  end

  @impl true
  def handle_event("create_website", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please provide a website URL")}
  end

  @impl true
  def handle_event("update_domain", _params, %{assigns: %{website: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Please add a website first")}
  end

  @impl true
  def handle_event("update_domain", %{"domain" => domain}, socket) do
    user_id = socket.assigns.user_id
    website = socket.assigns.website

    # Verify website belongs to user and update
    query =
      from w in Website,
        where: w.id == ^website.id and w.user_id == ^user_id

    case Repo.one(query) do
      nil ->
        {:noreply, socket}

      website ->
        changeset = Website.changeset(website, %{url: domain})

        case Repo.update(changeset) do
          {:ok, updated_website} ->
            {:noreply, socket |> assign(:website, updated_website) |> put_flash(:info, "Website URL updated")}

          {:error, _changeset} ->
            {:noreply, put_flash(socket, :error, "Failed to update website URL")}
        end
    end
  end

  @impl true
  def handle_event("dismiss_question", _params, %{assigns: %{website: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Please add a website first")}
  end

  @impl true
  def handle_event("dismiss_question", %{"question-id" => question_id}, socket) do
    user_id = socket.assigns.user_id
    website = socket.assigns.website

    # Verify the question belongs to this user's website before dismissing
    question = Repo.get(Shepherd.Websites.UserQuestion, question_id)

    cond do
      is_nil(question) ->
        {:noreply, put_flash(socket, :error, "Question not found")}

      question.entity_id != website.id ->
        {:noreply, put_flash(socket, :error, "Question does not belong to this website")}

      true ->
        case WebsiteManager.dismiss_question(user_id, question_id) do
          {:ok, _dismissed_question} ->
            socket =
              socket
              |> reload_questions(user_id, website.id)
              |> reload_complaints(user_id, website.id)

            {:noreply, socket}

          {:error, _} ->
            {:noreply, put_flash(socket, :error, "Failed to dismiss question")}
        end
    end
  end

  @impl true
  def handle_event("complete_command", _params, %{assigns: %{website: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Please add a website first")}
  end

  @impl true
  def handle_event("complete_command", %{"command-id" => command_id}, socket) do
    user_id = socket.assigns.user_id
    website = socket.assigns.website

    case CommandManager.complete_command(user_id, command_id) do
      {:ok, _completed_command} ->
        socket = socket |> reload_commands(user_id, website.id) |> refresh_notification_counts()
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("dismiss_command", _params, %{assigns: %{website: nil}} = socket) do
    {:noreply, put_flash(socket, :error, "Please add a website first")}
  end

  @impl true
  def handle_event("dismiss_command", %{"command-id" => command_id}, socket) do
    user_id = socket.assigns.user_id
    website = socket.assigns.website

    case CommandManager.dismiss_command(user_id, command_id) do
      {:ok, _dismissed_command} ->
        socket = socket |> reload_commands(user_id, website.id) |> refresh_notification_counts()
        {:noreply, socket}

      {:error, _} ->
        {:noreply, socket}
    end
  end

  defp website_sidebar(assigns) do
    ~H"""
    <div class="flex flex-col h-full bg-terminal border-r-2 border-green-500 terminal-glow overflow-auto">
      <div class="p-4 border-b-2 border-green-500m md:hidden">
        <h2 class="text-sm font-bold uppercase text-green-400 text-center">◆ Website</h2>
      </div>

      <div class="flex-1 p-3">
        <div class="space-y-2">
          <.sidebar_nav_link navigate={~p"/website?tab=commands"} active={@active_tab == "commands"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Commands</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/website?tab=complain"} active={@active_tab == "complain"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Complain</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/website?tab=report"} active={@active_tab == "report"}>
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Report</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link
            navigate={~p"/website?tab=brainstorm"}
            active={@active_tab == "brainstorm"}
          >
            <span class="text-green-400">►</span>
            <div class="ml-3 flex-1">
              <div class="text-xs font-bold uppercase">Brainstorm</div>
            </div>
          </.sidebar_nav_link>

          <div class="border-b border-green-500 opacity-30 my-2"></div>

          <.sidebar_nav_link navigate={~p"/website?tab=settings"} active={@active_tab == "settings"}>
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
          else:
            "bg-terminal border-green-500 border-opacity-30 text-green-500 opacity-60 hover:bg-green-500 hover:bg-opacity-20 hover:border-green-400 hover:text-green-300 hover:opacity-100"
        )
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp refresh_notification_counts(socket) do
    assign(socket, :notification_counts, Shepherd.LLM.ContextManager.compute_notification_counts(socket.assigns.user_id))
  end

  defp maybe_update_page_title(socket, tab) do
    title =
      case tab do
        "commands" -> "Commands"
        "complain" -> "Complain"
        "report" -> "Report"
        "brainstorm" -> "Brainstorm"
        "settings" -> "Settings"
        _ -> "Website"
      end

    assign(socket, :page_title, title)
  end

  attr :question, :map, required: true

  defp question_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal terminal-glow">
      <div class="p-3">
        <div class="mb-4">
          <h3 class="text-sm font-bold mb-3">{@question.question_text}</h3>

          <%= if @question.options && @question.options["choices"] do %>
            <div class="space-y-2">
              <%= for choice <- @question.options["choices"] do %>
                <button
                  phx-click="answer_question"
                  phx-value-question-id={@question.id}
                  phx-value-answer={choice}
                  class="w-full text-left border border-green-500 px-3 py-2 text-xs hover:bg-green-900 hover:bg-opacity-20 hover:border-green-400 transition-colors"
                >
                  <span class="text-green-400">►</span> {choice}
                </button>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="flex gap-2 justify-end pt-2 border-t border-green-500 border-opacity-30">
          <button
            phx-click="dismiss_question"
            phx-value-question-id={@question.id}
            class="border border-red-500 text-red-500 px-3 py-1 text-xs hover:bg-red-900 hover:bg-opacity-20 uppercase"
          >
            [Dismiss]
          </button>
        </div>
      </div>
    </div>
    """
  end

  attr :command, :map, required: true

  defp command_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal terminal-glow">
      <div class="p-3">
        <div class="flex items-start justify-between mb-2">
          <div class="flex items-center gap-2">
            <span class={[
              "text-xs px-2 py-0.5 border uppercase font-bold",
              urgency_class(@command.urgency)
            ]}>
              {@command.urgency}
            </span>
            <%= if @command.deadline do %>
              <span class="text-xs opacity-60">
                Due: {Calendar.strftime(@command.deadline, "%Y-%m-%d")}
              </span>
            <% end %>
          </div>
        </div>

        <div class="mb-3">
          <p class="text-sm font-bold mb-2">{@command.command_text}</p>
          <%= if @command.llm_reasoning do %>
            <div class="mt-2 p-2 border border-green-500 border-opacity-30 bg-black bg-opacity-20">
              <p class="text-xs opacity-70">
                <span class="text-green-400">Reasoning:</span>
                {@command.llm_reasoning}
              </p>
            </div>
          <% end %>
        </div>

        <div class="flex gap-2 justify-end pt-2 border-t border-green-500 border-opacity-30">
          <button
            phx-click="complete_command"
            phx-value-command-id={@command.id}
            class="border border-green-500 text-green-500 px-3 py-1 text-xs hover:bg-green-900 hover:bg-opacity-20 uppercase"
          >
            [Complete]
          </button>
          <button
            phx-click="dismiss_command"
            phx-value-command-id={@command.id}
            class="border border-red-500 text-red-500 px-3 py-1 text-xs hover:bg-red-900 hover:bg-opacity-20 uppercase"
          >
            [Dismiss]
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp urgency_class(urgency) do
    case urgency do
      "critical" -> "border-red-500 text-red-500"
      "high" -> "border-yellow-500 text-yellow-500"
      "medium" -> "border-green-400 text-green-400"
      "low" -> "border-green-500 text-green-500 opacity-60"
      _ -> "border-green-500 text-green-500"
    end
  end

  defp reload_questions(socket, user_id, website_id) do
    questions =
      case WebsiteManager.get_unanswered_questions(user_id, website_id) do
        {:ok, questions} -> questions
        {:error, _} -> []
      end

    assign(socket, :questions, questions)
  end

  defp reload_context(socket, user_id, website_id) do
    context =
      case WebsiteManager.get_context(user_id, website_id) do
        {:ok, context} -> context
        {:error, _} -> %{}
      end

    assign(socket, :context, context)
  end

  defp reload_commands(socket, user_id, website_id) do
    {:ok, commands} = CommandManager.get_pending_commands(user_id, "website", website_id)
    assign(socket, :commands, commands)
  end

  defp reload_complaints(socket, user_id, website_id) do
    complaints =
      case WebsiteManager.get_unanswered_questions_by_type(user_id, "website", website_id, "complaint") do
        {:ok, complaints} -> complaints
        {:error, _} -> []
      end

    assign(socket, :complaints, complaints)
  end

  attr :complaint, :map, required: true

  defp complaint_card(assigns) do
    ~H"""
    <div class="border-2 border-green-500 bg-terminal terminal-glow">
      <div class="p-3">
        <div class="flex items-start justify-between mb-3">
          <div class="flex items-center gap-2">
            <span class={[
              "text-xs px-2 py-0.5 border uppercase font-bold",
              complaint_severity_class(@complaint.severity)
            ]}>
              {@complaint.severity}
            </span>
            <%= if @complaint.category do %>
              <span class="text-xs opacity-60 uppercase">
                [{@complaint.category}]
              </span>
            <% end %>
          </div>
          <%= if @complaint.expires_at do %>
            <span class="text-xs opacity-40">
              Expires: {Calendar.strftime(@complaint.expires_at, "%m/%d")}
            </span>
          <% end %>
        </div>

        <div class="mb-4">
          <h3 class="text-sm font-bold mb-3">{@complaint.question_text}</h3>

          <%= if @complaint.options && @complaint.options["choices"] do %>
            <div class="space-y-2">
              <%= for choice <- @complaint.options["choices"] do %>
                <button
                  phx-click="answer_question"
                  phx-value-question-id={@complaint.id}
                  phx-value-answer={choice}
                  class="w-full text-left border border-green-500 px-3 py-2 text-xs hover:bg-green-900 hover:bg-opacity-20 hover:border-green-400 transition-colors"
                >
                  <span class="text-green-400">►</span> {choice}
                </button>
              <% end %>
            </div>
          <% end %>
        </div>

        <div class="flex gap-2 justify-end pt-2 border-t border-green-500 border-opacity-30">
          <button
            phx-click="dismiss_question"
            phx-value-question-id={@complaint.id}
            class="border border-red-500 text-red-500 px-3 py-1 text-xs hover:bg-red-900 hover:bg-opacity-20 uppercase"
          >
            [Dismiss]
          </button>
        </div>
      </div>
    </div>
    """
  end

  defp complaint_severity_class(severity) do
    case severity do
      "critical" -> "border-red-500 text-red-500"
      "warning" -> "border-yellow-500 text-yellow-500"
      "info" -> "border-green-400 text-green-400"
      _ -> "border-green-500 text-green-500"
    end
  end
end
