defmodule Shepherd.LLM.ContextManager do
  @moduledoc """
  Context manager bridging HQ LiveViews to domain subsystems.
  Provides a unified API for command, question, and feedback operations
  used by the HQ dashboard views.
  """

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.LLM.CommandManager
  alias Shepherd.LLM.FeedbackManager
  alias Shepherd.LLM.WebsiteManager
  alias Shepherd.Commands.Command

  # ── Commands ──────────────────────────────────────────────────────────

  @doc """
  Mark a command as completed.
  """
  def mark_command_completed(user_id, command_id) do
    CommandManager.complete_command(user_id, command_id)
  end

  @doc """
  Mark a command as dismissed.
  """
  def mark_command_dismissed(user_id, command_id) do
    CommandManager.dismiss_command(user_id, command_id)
  end

  @doc """
  Get aggregate command stats across all entity types for a user.
  """
  def get_command_overview(user_id) do
    CommandManager.get_command_stats(user_id)
  end

  @doc """
  Get pending commands grouped by entity_type.
  Returns a map of %{entity_type => [commands]}.
  """
  def get_commands_by_domain(user_id) do
    query =
      from c in Command,
        where: c.user_id == ^user_id and c.status == "pending",
        order_by: [
          asc:
            fragment(
              "CASE ? WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END",
              c.urgency
            ),
          asc: c.inserted_at
        ]

    commands = Repo.all(query)
    {:ok, Enum.group_by(commands, & &1.entity_type)}
  end

  # ── Feedback ──────────────────────────────────────────────────────────

  @doc """
  Get active feedback for a user.
  """
  def get_active_feedback(user_id) do
    FeedbackManager.get_active_feedback(user_id)
  end

  @doc """
  Get feedback statistics for a user.
  """
  def get_feedback_stats(user_id) do
    FeedbackManager.get_feedback_stats(user_id)
  end

  # ── Questions ─────────────────────────────────────────────────────────

  @doc """
  Get unanswered questions for a specific entity.
  """
  def get_unanswered_questions(user_id, entity_type, entity_id) do
    WebsiteManager.get_unanswered_questions_by_entity(user_id, entity_type, entity_id)
  end

  # ── Notification Counts ───────────────────────────────────────────────

  @doc """
  Compute notification badge counts for the navbar.

  Returns a map of domain keys to non-zero badge counts, e.g.:
      %{"hq" => 2, "website" => 5, "app" => 1}

  The "hq" key uses the critical feedback count from FeedbackManager.
  All other keys use the pending command count for that entity_type.
  Only domains with a count > 0 are included in the result.
  """
  def compute_notification_counts(user_id) do
    # Pending command counts grouped by entity_type
    command_counts =
      from(c in Command,
        where: c.user_id == ^user_id and c.status == "pending",
        group_by: c.entity_type,
        select: {c.entity_type, count(c.id)}
      )
      |> Repo.all()
      |> Map.new()

    # Critical feedback count for the HQ badge
    feedback_stats = FeedbackManager.get_feedback_stats(user_id)
    critical_count = feedback_stats.critical

    domain_keys = ["website", "app", "marketing", "funnel", "sales", "hr", "customers"]

    domain_counts =
      for key <- domain_keys,
          count = Map.get(command_counts, key, 0),
          count > 0,
          into: %{},
          do: {key, count}

    if critical_count > 0 do
      Map.put(domain_counts, "hq", critical_count)
    else
      domain_counts
    end
  end

  # ── Cross-domain Summary ──────────────────────────────────────────────

  @doc """
  Get a summary of all pending work across domains for the HQ dashboard.
  Returns a map with counts per domain and total counts.
  """
  def get_dashboard_summary(user_id) do
    {:ok, commands_by_domain} = get_commands_by_domain(user_id)

    command_counts =
      commands_by_domain
      |> Enum.map(fn {domain, commands} -> {domain, length(commands)} end)
      |> Map.new()

    total_commands =
      command_counts
      |> Map.values()
      |> Enum.sum()

    feedback_stats = get_feedback_stats(user_id)

    %{
      commands_by_domain: command_counts,
      total_pending_commands: total_commands,
      feedback: feedback_stats
    }
  end
end
