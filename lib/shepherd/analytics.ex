defmodule Shepherd.Analytics do
  @moduledoc """
  Context module for analytics operations.
  Provides query functions for action logs and user behavior metrics.
  """

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.Analytics.{ActionLog, UserBehaviorMetric}

  # ── Action Logs ──────────────────────────────────────────────────────

  @doc """
  Get recent action logs for a user, ordered newest first.
  """
  def list_recent_actions(user_id, limit \\ 20) do
    Repo.all(
      from a in ActionLog,
        where: a.user_id == ^user_id,
        order_by: [desc: a.timestamp],
        limit: ^limit
    )
  end

  @doc """
  Get action logs for a user filtered by action type.
  """
  def list_actions_by_type(user_id, action_type, limit \\ 50) do
    Repo.all(
      from a in ActionLog,
        where: a.user_id == ^user_id and a.action_type == ^action_type,
        order_by: [desc: a.timestamp],
        limit: ^limit
    )
  end

  @doc """
  Count actions by type for a user within a time period.
  Returns a map of %{action_type => count}.
  """
  def action_counts_since(user_id, since) do
    Repo.all(
      from a in ActionLog,
        where: a.user_id == ^user_id and a.timestamp >= ^since,
        group_by: a.action_type,
        select: {a.action_type, count(a.id)}
    )
    |> Map.new()
  end

  # ── User Behavior Metrics ──────────────────────────────────────────

  @doc """
  Get or create the behavior metrics record for a user.
  """
  def get_or_create_metrics(user_id) do
    case Repo.one(from m in UserBehaviorMetric, where: m.user_id == ^user_id) do
      nil ->
        %UserBehaviorMetric{}
        |> UserBehaviorMetric.changeset(%{user_id: user_id})
        |> Repo.insert()

      metric ->
        {:ok, metric}
    end
  end

  @doc """
  Update behavior metrics for a user.
  """
  def update_metrics(user_id, attrs) do
    case get_or_create_metrics(user_id) do
      {:ok, metric} ->
        metric
        |> UserBehaviorMetric.changeset(attrs)
        |> Repo.update()

      error ->
        error
    end
  end

  @doc """
  Recalculate all metrics for a user from their action logs.
  Called by the MetricsAggregationWorker.
  """
  def recalculate_metrics(user_id) do
    # Count commands
    command_stats = count_by_action_and_status(user_id, "command")
    question_stats = count_by_action_and_status(user_id, "question")

    total_completed = Map.get(command_stats, "command_completed", 0)
    total_dismissed = Map.get(command_stats, "command_dismissed", 0)
    total_questions = Map.get(question_stats, "question_answered", 0)
    total_q_dismissed = Map.get(question_stats, "question_dismissed", 0)

    total_commands = total_completed + total_dismissed
    total_q = total_questions + total_q_dismissed

    command_completion_rate =
      if total_commands > 0, do: Decimal.div(Decimal.new(total_completed), Decimal.new(total_commands)), else: nil

    question_completion_rate =
      if total_q > 0, do: Decimal.div(Decimal.new(total_questions), Decimal.new(total_q)), else: nil

    dismissal_count = total_dismissed + total_q_dismissed
    total_all = total_commands + total_q

    dismissal_rate =
      if total_all > 0, do: Decimal.div(Decimal.new(dismissal_count), Decimal.new(total_all)), else: nil

    # Calculate procrastination score
    overdue_count = count_overdue_commands(user_id)

    procrastination_score =
      UserBehaviorMetric.calculate_procrastination_score(
        overdue_count: overdue_count,
        dismissal_rate: if(dismissal_rate, do: Decimal.to_float(dismissal_rate), else: 0.0)
      )

    attrs = %{
      total_commands_completed: total_completed,
      total_commands_dismissed: total_dismissed,
      total_questions_answered: total_questions,
      command_completion_rate: command_completion_rate,
      question_completion_rate: question_completion_rate,
      dismissal_rate: dismissal_rate,
      overdue_command_count: overdue_count,
      procrastination_score: Decimal.from_float(procrastination_score),
      preferred_communication_style: UserBehaviorMetric.recommend_communication_style(procrastination_score)
    }

    update_metrics(user_id, attrs)
  end

  defp count_by_action_and_status(user_id, entity_prefix) do
    Repo.all(
      from a in ActionLog,
        where: a.user_id == ^user_id and like(a.action_type, ^"#{entity_prefix}_%"),
        group_by: a.action_type,
        select: {a.action_type, count(a.id)}
    )
    |> Map.new()
  end

  defp count_overdue_commands(user_id) do
    alias Shepherd.Commands.Command

    Repo.one(
      from c in Command,
        where: c.user_id == ^user_id and c.status == "overdue",
        select: count(c.id)
    ) || 0
  end
end
