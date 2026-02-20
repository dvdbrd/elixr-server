defmodule Shepherd.Analytics.UserBehaviorMetric do
  @moduledoc """
  Schema for aggregated user behavioral patterns.
  Calculated from action_logs to enable LLM personality adaptation and procrastination detection.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_behavior_metrics" do
    field :user_id, :integer

    # Response patterns (in seconds)
    field :avg_question_response_time, :integer
    field :avg_command_completion_time, :integer

    # Completion rates (0.0 to 1.0)
    field :question_completion_rate, :decimal
    field :command_completion_rate, :decimal
    field :dismissal_rate, :decimal

    # Procrastination indicators
    field :procrastination_score, :decimal
    field :overdue_command_count, :integer, default: 0

    # Activity patterns (stored as JSONB)
    field :active_hours, :map, default: %{}
    field :active_days, :map, default: %{}

    # LLM personality adaptation
    field :preferred_communication_style, :string
    field :responds_to_urgency, :boolean, default: true

    # Counters
    field :total_questions_answered, :integer, default: 0
    field :total_commands_completed, :integer, default: 0
    field :total_commands_dismissed, :integer, default: 0

    field :updated_at, :utc_datetime
  end

  @doc false
  def changeset(metric, attrs) do
    metric
    |> cast(attrs, [
      :user_id,
      :avg_question_response_time,
      :avg_command_completion_time,
      :question_completion_rate,
      :command_completion_rate,
      :dismissal_rate,
      :procrastination_score,
      :overdue_command_count,
      :active_hours,
      :active_days,
      :preferred_communication_style,
      :responds_to_urgency,
      :total_questions_answered,
      :total_commands_completed,
      :total_commands_dismissed,
      :updated_at
    ])
    |> validate_required([:user_id])
    |> validate_number(:question_completion_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:command_completion_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:dismissal_rate, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> validate_number(:procrastination_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 10)
    |> validate_inclusion(:preferred_communication_style, [
      "direct",
      "encouraging",
      "harsh",
      "neutral"
    ])
    |> unique_constraint(:user_id)
    |> maybe_set_updated_at()
  end

  defp maybe_set_updated_at(changeset) do
    put_change(changeset, :updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Get communication style based on procrastination score.
  """
  def recommend_communication_style(procrastination_score) when procrastination_score >= 8.0 do
    "harsh"
  end

  def recommend_communication_style(procrastination_score) when procrastination_score >= 5.0 do
    "direct"
  end

  def recommend_communication_style(procrastination_score) when procrastination_score >= 2.0 do
    "encouraging"
  end

  def recommend_communication_style(_), do: "neutral"

  @doc """
  Determine if user is procrastinating based on metrics.
  """
  def procrastinating?(%__MODULE__{} = metric) do
    metric.procrastination_score >= 6.0 or
      metric.overdue_command_count >= 3 or
      (metric.command_completion_rate || 1.0) < 0.5
  end

  @doc """
  Calculate procrastination score from raw data.
  Returns a score from 0-10 where higher = more procrastination.
  """
  def calculate_procrastination_score(opts) do
    overdue_count = Keyword.get(opts, :overdue_count, 0)
    avg_delay_hours = Keyword.get(opts, :avg_delay_hours, 0)
    dismissal_rate = Keyword.get(opts, :dismissal_rate, 0.0)

    # Weighted formula
    overdue_score = min(overdue_count * 2.0, 5.0)
    delay_score = min(avg_delay_hours / 24.0, 3.0)
    dismissal_score = dismissal_rate * 2.0

    total = overdue_score + delay_score + dismissal_score
    min(total, 10.0)
  end
end
