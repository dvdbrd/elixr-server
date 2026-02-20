defmodule Shepherd.Repo.Migrations.CreateShepherdTables do
  use Ecto.Migration

  def up do
    # ============================================================================
    # CORE DOMAIN TABLES
    # ============================================================================

    # Websites table - stores user websites being managed
    create table(:websites, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :url, :string, size: 500, null: false
      add :name, :string, size: 255
      add :github_repo_url, :string, size: 500
      add :last_scanned_at, :utc_datetime
      add :status, :string, size: 20, default: "active"

      timestamps(type: :utc_datetime)
    end

    create index(:websites, [:user_id])
    create index(:websites, [:status])

    # ============================================================================
    # CONTEXT STORAGE TABLES
    # ============================================================================

    # Website contexts - legacy JSONB storage (will migrate to fragments)
    create table(:website_contexts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :website_id, references(:websites, type: :binary_id, on_delete: :delete_all),
        null: false
      add :context_document, :map, null: false, default: %{}
      add :updated_at, :utc_datetime
    end

    create unique_index(:website_contexts, [:website_id])

    # Context fragments - optimized storage for LLM efficiency
    # Allows loading only needed context parts instead of entire document
    create table(:context_fragments, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Polymorphic association (supports websites, marketing, sales, etc.)
      add :entity_type, :string, size: 50, null: false
      add :entity_id, :binary_id, null: false

      # Fragment type (concept, active_tasks, behavioral_notes, scan_cache)
      add :fragment_type, :string, size: 50, null: false

      # Fragment data (keep small and focused)
      add :content, :map, null: false, default: %{}

      # Metadata
      add :updated_by, :string, size: 20, default: "system"
      add :access_frequency, :string, size: 20, default: "medium"

      add :updated_at, :utc_datetime
    end

    create unique_index(:context_fragments, [:entity_type, :entity_id, :fragment_type],
             name: :context_fragments_unique
           )

    create index(:context_fragments, [:entity_type, :entity_id])
    create index(:context_fragments, [:user_id])

    # ============================================================================
    # INTERACTION TABLES
    # ============================================================================

    # User questions - LLM asks questions to gather information
    # Now polymorphic: supports both onboarding questions and complaint questions
    create table(:user_questions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Polymorphic association (supports websites, marketing, sales, etc.)
      add :entity_type, :string, size: 50, null: false
      add :entity_id, :binary_id, null: false

      # Backward compatibility - kept for existing queries
      add :website_id, references(:websites, type: :binary_id, on_delete: :delete_all)

      # Question content
      add :question_text, :text, null: false
      add :options, :map, null: false
      add :answer, :map

      # Question classification
      add :question_type, :string, size: 50, default: "onboarding"
      add :severity, :string, size: 20, default: "info"
      add :category, :string, size: 50
      add :generated_by, :string, size: 20, default: "llm"

      # Status tracking
      add :answered_at, :utc_datetime
      add :status, :string, size: 20, default: "pending"
      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:user_questions, [:user_id, :status])
    create index(:user_questions, [:entity_type, :entity_id])
    create index(:user_questions, [:user_id, :entity_type, :entity_id, :status])
    create index(:user_questions, [:question_type, :status])
    create index(:user_questions, [:expires_at], where: "status = 'pending'")
    create index(:user_questions, [:website_id, :status])
    create index(:user_questions, [:status])

    # Commands - LLM issues orders to users (supports all domains via polymorphism)
    create table(:commands, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Polymorphic association
      add :entity_type, :string, size: 50, null: false
      add :entity_id, :binary_id, null: false

      # Command details
      add :command_text, :text, null: false
      add :urgency, :string, size: 20, default: "medium"
      add :status, :string, size: 20, default: "pending"

      # Tracking
      add :created_by, :string, size: 20, default: "llm"
      add :llm_reasoning, :text

      # Timing
      add :deadline, :utc_datetime
      add :completed_at, :utc_datetime
      add :dismissed_at, :utc_datetime

      # Behavioral data
      add :time_to_complete, :integer
      add :reminded_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:commands, [:user_id, :status])
    create index(:commands, [:entity_type, :entity_id])
    create index(:commands, [:status])
    create index(:commands, [:deadline], where: "status = 'pending'")
    create index(:commands, [:urgency, :status])

    # ============================================================================
    # TRACKING & ANALYTICS TABLES
    # ============================================================================

    # Action logs - universal audit trail for all user actions
    create table(:action_logs, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # What happened
      add :action_type, :string, size: 50, null: false

      # Where it happened (polymorphic)
      add :entity_type, :string, size: 50
      add :entity_id, :binary_id

      # Details (keep minimal for performance)
      add :metadata, :map, default: %{}

      # When
      add :timestamp, :utc_datetime, null: false
    end

    create index(:action_logs, [:user_id, :timestamp])
    create index(:action_logs, [:action_type, :timestamp])
    create index(:action_logs, [:entity_type, :entity_id])

    # User behavior metrics - aggregated behavioral patterns
    create table(:user_behavior_metrics, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, on_delete: :delete_all), null: false

      # Response patterns (in seconds)
      add :avg_question_response_time, :integer
      add :avg_command_completion_time, :integer

      # Completion rates (0.0 to 1.0)
      add :question_completion_rate, :decimal, precision: 5, scale: 4
      add :command_completion_rate, :decimal, precision: 5, scale: 4
      add :dismissal_rate, :decimal, precision: 5, scale: 4

      # Procrastination indicators
      add :procrastination_score, :decimal, precision: 4, scale: 2
      add :overdue_command_count, :integer, default: 0

      # Activity patterns (stored as JSONB arrays)
      add :active_hours, :map, default: %{}
      add :active_days, :map, default: %{}

      # LLM personality adaptation
      add :preferred_communication_style, :string, size: 50
      add :responds_to_urgency, :boolean, default: true

      # Counters
      add :total_questions_answered, :integer, default: 0
      add :total_commands_completed, :integer, default: 0
      add :total_commands_dismissed, :integer, default: 0

      add :updated_at, :utc_datetime
    end

    create unique_index(:user_behavior_metrics, [:user_id])
    create index(:user_behavior_metrics, [:procrastination_score])
  end

  def down do
    drop table(:user_behavior_metrics)
    drop table(:action_logs)
    drop table(:commands)
    drop table(:user_questions)
    drop table(:context_fragments)
    drop table(:website_contexts)
    drop table(:websites)
  end
end
