defmodule Shepherd.AnalyticsFixtures do
  @moduledoc """
  Test helpers for creating analytics entities.
  """

  alias Shepherd.Repo
  alias Shepherd.Analytics.{ActionLog, UserBehaviorMetric}

  def valid_action_log_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      user_id: nil,
      action_type: "command_completed",
      entity_type: "website",
      entity_id: Ecto.UUID.generate(),
      metadata: %{},
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def action_log_fixture(attrs \\ %{}) do
    attrs = valid_action_log_attributes(attrs)

    if is_nil(attrs.user_id) do
      raise "action_log_fixture requires :user_id"
    end

    %ActionLog{}
    |> ActionLog.changeset(Map.take(attrs, [
      :user_id, :action_type, :entity_type, :entity_id, :metadata, :timestamp
    ]))
    |> Repo.insert!()
  end

  def valid_user_behavior_metric_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      user_id: nil,
      avg_question_response_time: 300,
      avg_command_completion_time: 3600,
      question_completion_rate: Decimal.new("0.75"),
      command_completion_rate: Decimal.new("0.60"),
      dismissal_rate: Decimal.new("0.10"),
      procrastination_score: Decimal.new("3.5"),
      overdue_command_count: 1,
      total_questions_answered: 10,
      total_commands_completed: 8,
      total_commands_dismissed: 2,
      preferred_communication_style: "encouraging",
      responds_to_urgency: true
    })
  end

  def user_behavior_metric_fixture(attrs \\ %{}) do
    attrs = valid_user_behavior_metric_attributes(attrs)

    if is_nil(attrs.user_id) do
      raise "user_behavior_metric_fixture requires :user_id"
    end

    %UserBehaviorMetric{}
    |> UserBehaviorMetric.changeset(Map.take(attrs, [
      :user_id, :avg_question_response_time, :avg_command_completion_time,
      :question_completion_rate, :command_completion_rate, :dismissal_rate,
      :procrastination_score, :overdue_command_count, :total_questions_answered,
      :total_commands_completed, :total_commands_dismissed,
      :preferred_communication_style, :responds_to_urgency,
      :active_hours, :active_days
    ]))
    |> Repo.insert!()
  end
end
