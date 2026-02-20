defmodule Shepherd.Analytics.ActionLog do
  @moduledoc """
  Schema for tracking all user actions for behavioral analysis.
  Provides audit trail and data for calculating user behavior metrics.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}

  schema "action_logs" do
    field :user_id, :integer

    # What happened
    field :action_type, :string

    # Where it happened (polymorphic)
    field :entity_type, :string
    field :entity_id, :binary_id

    # Details (keep minimal for performance)
    field :metadata, :map, default: %{}

    # When
    field :timestamp, :utc_datetime
  end

  @valid_action_types [
    "question_answered",
    "question_dismissed",
    "command_completed",
    "command_dismissed",
    "context_updated",
    "website_added",
    "website_scanned",
    "settings_updated"
  ]

  @doc false
  def changeset(action_log, attrs) do
    action_log
    |> cast(attrs, [:user_id, :action_type, :entity_type, :entity_id, :metadata, :timestamp])
    |> validate_required([:user_id, :action_type, :timestamp])
    |> validate_inclusion(:action_type, @valid_action_types)
    |> maybe_set_timestamp()
  end

  defp maybe_set_timestamp(changeset) do
    case get_field(changeset, :timestamp) do
      nil -> put_change(changeset, :timestamp, DateTime.utc_now() |> DateTime.truncate(:second))
      _ -> changeset
    end
  end

  @doc """
  Create an action log entry.
  """
  def log(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Shepherd.Repo.insert()
  end

  @doc """
  Convenience function to log a question being answered.
  """
  def log_question_answered(user_id, question_id, answer, response_time_seconds) do
    log(%{
      user_id: user_id,
      action_type: "question_answered",
      entity_type: "user_question",
      entity_id: question_id,
      metadata: %{
        "answer" => answer,
        "response_time_seconds" => response_time_seconds
      }
    })
  end

  @doc """
  Convenience function to log a command being completed.
  """
  def log_command_completed(user_id, command_id, time_to_complete) do
    log(%{
      user_id: user_id,
      action_type: "command_completed",
      entity_type: "command",
      entity_id: command_id,
      metadata: %{
        "time_to_complete" => time_to_complete
      }
    })
  end
end
