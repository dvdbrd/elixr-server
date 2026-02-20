defmodule Shepherd.Repo.Migrations.CreateLlmFeedbackTable do
  use Ecto.Migration

  def change do
    create table(:llm_feedback, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Feedback metadata
      add :feedback_type, :string, size: 50, null: false
      # Types: "daily_summary", "weekly_summary", "procrastination_warning",
      #        "encouragement", "harsh_warning", "performance_review"

      add :severity, :string, size: 20, default: "info", null: false
      # Values: "info", "warning", "critical", "success"

      add :tone, :string, size: 20, default: "neutral", null: false
      # Values: "harsh", "direct", "encouraging", "neutral", "robotic"

      # The actual feedback text from LLM
      add :title, :string, size: 255, null: false
      add :message, :text, null: false

      # Optional context data (JSONB for flexibility)
      add :context_data, :map, default: %{}, null: false
      # Example: %{procrastination_score: 7.2, overdue_count: 3, completion_rate: 0.45}

      # User interaction tracking
      add :acknowledged_at, :utc_datetime
      add :dismissed_at, :utc_datetime
      add :status, :string, size: 20, default: "active", null: false
      # Values: "active", "acknowledged", "dismissed", "expired"

      # Expiration for time-sensitive feedback
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:llm_feedback, [:user_id])
    create index(:llm_feedback, [:user_id, :status])
    create index(:llm_feedback, [:feedback_type])
    create index(:llm_feedback, [:severity])
    create index(:llm_feedback, [:expires_at])
  end
end
