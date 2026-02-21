alias Shepherd.Repo
alias Shepherd.Commands.Command
alias Shepherd.LLM.Feedback
alias Shepherd.Websites.UserQuestion
import Ecto.Query

user = Repo.get_by!(Shepherd.Accounts.User, email: "test@example.com")
website = Repo.one!(Shepherd.Websites.Website)

# Clean up any partial data from previous seed attempts
Repo.delete_all(from c in Command, where: c.user_id == ^user.id)
Repo.delete_all(from f in Feedback, where: f.user_id == ^user.id)
Repo.delete_all(from q in UserQuestion, where: q.user_id == ^user.id)
IO.puts("Cleaned up existing data")

# Generate stable UUIDs for non-website domains
app_id = Ecto.UUID.generate()
marketing_id = Ecto.UUID.generate()
sales_id = Ecto.UUID.generate()
funnel_id = Ecto.UUID.generate()
hr_id = Ecto.UUID.generate()
customers_id = Ecto.UUID.generate()

# ── Commands across all domains ──
commands = [
  # Website commands
  %{user_id: user.id, entity_type: "website", entity_id: website.id, command_text: "Add trust badges and SSL certificate icon above the fold", urgency: "critical", status: "pending", created_by: "llm", llm_reasoning: "Homepage lacks visible trust signals — visitors bounce before scrolling"},
  %{user_id: user.id, entity_type: "website", entity_id: website.id, command_text: "Rewrite hero section CTA from generic to benefit-driven", urgency: "high", status: "pending", created_by: "llm", llm_reasoning: "Current CTA 'Learn More' converts at 0.8% — industry avg is 3.2%"},
  %{user_id: user.id, entity_type: "website", entity_id: website.id, command_text: "Add customer testimonials section with photos", urgency: "medium", status: "pending", created_by: "llm", llm_reasoning: "Social proof is missing entirely from the landing page"},
  %{user_id: user.id, entity_type: "website", entity_id: website.id, command_text: "Compress hero image — currently 2.4MB", urgency: "low", status: "completed", created_by: "llm", llm_reasoning: "Page load time exceeds 4s on mobile"},
  # App commands
  %{user_id: user.id, entity_type: "app", entity_id: app_id, command_text: "Fix broken OAuth callback URL in production config", urgency: "critical", status: "pending", created_by: "llm", llm_reasoning: "Social login fails silently — users cannot authenticate via Google"},
  %{user_id: user.id, entity_type: "app", entity_id: app_id, command_text: "Add error boundary to prevent white screen crashes", urgency: "high", status: "pending", created_by: "llm", llm_reasoning: "Unhandled JS errors cause the entire app to become unresponsive"},
  %{user_id: user.id, entity_type: "app", entity_id: app_id, command_text: "Implement request caching for API responses", urgency: "medium", status: "pending", created_by: "llm", llm_reasoning: "Repeated API calls slow down page navigation"},
  # Marketing commands
  %{user_id: user.id, entity_type: "marketing", entity_id: marketing_id, command_text: "A/B test email subject lines for the welcome sequence", urgency: "high", status: "pending", created_by: "llm", llm_reasoning: "Welcome email open rate is 18% — should be 35%+"},
  %{user_id: user.id, entity_type: "marketing", entity_id: marketing_id, command_text: "Create retargeting campaign for cart abandoners", urgency: "medium", status: "pending", created_by: "llm", llm_reasoning: "67% cart abandonment rate with zero follow-up"},
  # Sales commands
  %{user_id: user.id, entity_type: "sales", entity_id: sales_id, command_text: "Follow up with 3 qualified leads from last week demo", urgency: "critical", status: "pending", created_by: "llm", llm_reasoning: "Leads go cold after 48 hours — these are 5 days old"},
  %{user_id: user.id, entity_type: "sales", entity_id: sales_id, command_text: "Update pricing page with new enterprise tier", urgency: "medium", status: "pending", created_by: "llm", llm_reasoning: "Enterprise prospects ask for custom pricing not shown on site"},
  # Funnel commands
  %{user_id: user.id, entity_type: "funnel", entity_id: funnel_id, command_text: "Fix checkout page drop-off — form has 12 fields", urgency: "high", status: "pending", created_by: "llm", llm_reasoning: "Step 3→4 conversion is 23% vs 60% benchmark. Too many required fields."},
  # HR commands
  %{user_id: user.id, entity_type: "hr", entity_id: hr_id, command_text: "Post senior developer job listing on LinkedIn", urgency: "medium", status: "pending", created_by: "llm", llm_reasoning: "Engineering team is at 80% capacity with 2 open reqs"},
  # Customers commands
  %{user_id: user.id, entity_type: "customers", entity_id: customers_id, command_text: "Respond to 5 negative NPS survey responses", urgency: "high", status: "pending", created_by: "llm", llm_reasoning: "Detractor responses older than 72h without follow-up"},
  %{user_id: user.id, entity_type: "customers", entity_id: customers_id, command_text: "Schedule quarterly business review with top 3 accounts", urgency: "medium", status: "pending", created_by: "llm", llm_reasoning: "Renewal dates approaching — no QBR scheduled"},
  # Some completed/dismissed for stats
  %{user_id: user.id, entity_type: "website", entity_id: website.id, command_text: "Fix mobile responsive layout on pricing page", urgency: "high", status: "completed", created_by: "llm", llm_reasoning: "Pricing page is unusable on mobile devices"},
  %{user_id: user.id, entity_type: "marketing", entity_id: marketing_id, command_text: "Set up UTM tracking for all social media links", urgency: "low", status: "dismissed", created_by: "llm", llm_reasoning: "Cannot attribute traffic sources without UTM params"},
  %{user_id: user.id, entity_type: "sales", entity_id: sales_id, command_text: "Clean up stale pipeline deals older than 90 days", urgency: "low", status: "completed", created_by: "llm", llm_reasoning: "Pipeline value is inflated by dead deals"},
]

Enum.each(commands, fn attrs ->
  %Command{}
  |> Command.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(commands)} commands")

# ── Feedback ──
feedbacks = [
  %{user_id: user.id, feedback_type: "procrastination_warning", severity: "critical", tone: "harsh", title: "3 Critical Items Ignored for 5+ Days", message: "You have 3 critical-urgency commands sitting untouched. Sales leads going cold, OAuth broken, website lacks trust signals. Every day you delay costs conversions.", context_data: %{}, status: "active", expires_at: DateTime.utc_now() |> DateTime.add(7 * 86400, :second) |> DateTime.truncate(:second)},
  %{user_id: user.id, feedback_type: "performance_review", severity: "warning", tone: "direct", title: "Website Conversion Below Industry Average", message: "Your homepage CTA converts at 0.8% while the industry average is 3.2%. The trust badges and testimonials commands would directly address this gap.", context_data: %{}, status: "active", expires_at: DateTime.utc_now() |> DateTime.add(14 * 86400, :second) |> DateTime.truncate(:second)},
  %{user_id: user.id, feedback_type: "encouragement", severity: "info", tone: "encouraging", title: "Good Progress on Technical Debt", message: "You completed the mobile layout fix and image compression. Keep this momentum going.", context_data: %{}, status: "active", expires_at: DateTime.utc_now() |> DateTime.add(3 * 86400, :second) |> DateTime.truncate(:second)},
  %{user_id: user.id, feedback_type: "daily_summary", severity: "info", tone: "robotic", title: "Daily Status Report", message: "PENDING: 15 commands across 7 domains. CRITICAL: 3. HIGH: 5. MEDIUM: 5. Recommendation: Address critical items in sales and website domains first.", context_data: %{}, status: "active", expires_at: DateTime.utc_now() |> DateTime.add(1 * 86400, :second) |> DateTime.truncate(:second)},
  %{user_id: user.id, feedback_type: "harsh_warning", severity: "warning", tone: "harsh", title: "Cart Abandonment is Hemorrhaging Revenue", message: "67% of users who add items to cart leave without purchasing. You have ZERO retargeting in place.", context_data: %{}, status: "active", expires_at: DateTime.utc_now() |> DateTime.add(5 * 86400, :second) |> DateTime.truncate(:second)},
]

Enum.each(feedbacks, fn attrs ->
  %Feedback{}
  |> Feedback.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(feedbacks)} feedback items")

# ── Questions ──
questions = [
  %{user_id: user.id, entity_type: "website", entity_id: website.id, website_id: website.id, question_text: "What is the primary action you want visitors to take on your homepage?", options: %{"choices" => ["Book a tour", "Request a quote", "Sign up for newsletter", "Contact us"]}, question_type: "onboarding", severity: "info", status: "pending", generated_by: "llm"},
  %{user_id: user.id, entity_type: "website", entity_id: website.id, website_id: website.id, question_text: "Do you currently have customer testimonials or reviews available?", options: %{"choices" => ["Yes, many", "A few", "None yet"]}, question_type: "onboarding", severity: "info", status: "pending", generated_by: "llm"},
  %{user_id: user.id, entity_type: "website", entity_id: website.id, website_id: website.id, question_text: "The checkout form requires 12 fields but most competitors use 5-6. Can we simplify?", options: %{"choices" => ["Yes, reduce to essentials", "Keep all fields", "Need to discuss"]}, question_type: "complaint", severity: "warning", status: "pending", generated_by: "llm", category: "conversion"},
]

Enum.each(questions, fn attrs ->
  %UserQuestion{}
  |> UserQuestion.changeset(attrs)
  |> Repo.insert!()
end)

IO.puts("Created #{length(questions)} questions")
IO.puts("Done seeding test data.")
