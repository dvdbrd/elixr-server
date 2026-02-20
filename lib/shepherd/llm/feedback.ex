defmodule Shepherd.LLM.Feedback do
  @moduledoc """
  Schema for LLM-generated feedback and summaries for users.

  Feedback types:
  - daily_summary: Daily performance overview
  - weekly_summary: Weekly recap
  - procrastination_warning: User is falling behind
  - encouragement: Positive reinforcement
  - harsh_warning: Escalated warnings for severe procrastination
  - performance_review: Periodic deep analysis
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @feedback_types ~w(daily_summary weekly_summary procrastination_warning encouragement harsh_warning performance_review)
  @severities ~w(info warning critical success)
  @tones ~w(harsh direct encouraging neutral robotic)
  @statuses ~w(active acknowledged dismissed expired)

  schema "llm_feedback" do
    field :user_id, :integer
    field :feedback_type, :string
    field :severity, :string, default: "info"
    field :tone, :string, default: "neutral"
    field :title, :string
    field :message, :string
    field :context_data, :map, default: %{}
    field :acknowledged_at, :utc_datetime
    field :dismissed_at, :utc_datetime
    field :status, :string, default: "active"
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc """
  Standard changeset for creating/updating feedback.
  """
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [
      :user_id,
      :feedback_type,
      :severity,
      :tone,
      :title,
      :message,
      :context_data,
      :status,
      :expires_at
    ])
    |> validate_required([:user_id, :feedback_type, :title, :message])
    |> validate_inclusion(:feedback_type, @feedback_types)
    |> validate_inclusion(:severity, @severities)
    |> validate_inclusion(:tone, @tones)
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:title, min: 5, max: 255)
    |> validate_length(:message, min: 10)
  end

  @doc """
  Changeset for acknowledging feedback.
  """
  def acknowledge_changeset(feedback, attrs \\ %{}) do
    feedback
    |> cast(attrs, [:acknowledged_at])
    |> put_change(:acknowledged_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:status, "acknowledged")
  end

  @doc """
  Changeset for dismissing feedback.
  """
  def dismiss_changeset(feedback, attrs \\ %{}) do
    feedback
    |> cast(attrs, [:dismissed_at])
    |> put_change(:dismissed_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> put_change(:status, "dismissed")
  end

  @doc """
  Returns icon/symbol for feedback type.
  """
  def type_icon(feedback_type) do
    case feedback_type do
      "daily_summary" -> "📊"
      "weekly_summary" -> "📈"
      "procrastination_warning" -> "⚠️"
      "encouragement" -> "✨"
      "harsh_warning" -> "🔥"
      "performance_review" -> "🎯"
      _ -> "💬"
    end
  end

  @doc """
  Returns CSS class for severity styling.
  """
  def severity_class(severity) do
    case severity do
      "critical" -> "border-red-500 text-red-500"
      "warning" -> "border-yellow-500 text-yellow-500"
      "success" -> "border-green-400 text-green-400"
      "info" -> "border-green-500 text-green-500"
      _ -> "border-green-500 text-green-500"
    end
  end

  @doc """
  Returns terminal symbol for severity.
  """
  def severity_symbol(severity) do
    case severity do
      "critical" -> "✕"
      "warning" -> "▲"
      "success" -> "●"
      "info" -> "◉"
      _ -> "○"
    end
  end
end
