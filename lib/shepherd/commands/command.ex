defmodule Shepherd.Commands.Command do
  @moduledoc """
  Schema for commands issued by LLM to users.
  Uses polymorphic associations to support websites, marketing, sales, etc.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "commands" do
    field :user_id, :integer

    # Polymorphic association
    field :entity_type, :string
    field :entity_id, :binary_id

    # Command details
    field :command_text, :string
    field :urgency, :string, default: "medium"
    field :status, :string, default: "pending"

    # Tracking
    field :created_by, :string, default: "llm"
    field :llm_reasoning, :string

    # Timing
    field :deadline, :utc_datetime
    field :completed_at, :utc_datetime
    field :dismissed_at, :utc_datetime

    # Behavioral data
    field :time_to_complete, :integer
    field :reminded_count, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(command, attrs) do
    command
    |> cast(attrs, [
      :user_id,
      :entity_type,
      :entity_id,
      :command_text,
      :urgency,
      :status,
      :created_by,
      :llm_reasoning,
      :deadline,
      :completed_at,
      :dismissed_at,
      :time_to_complete,
      :reminded_count
    ])
    |> validate_required([:user_id, :entity_type, :entity_id, :command_text])
    |> validate_inclusion(:urgency, ["low", "medium", "high", "critical"])
    |> validate_inclusion(:status, ["pending", "in_progress", "completed", "dismissed", "overdue"])
    |> validate_inclusion(:created_by, ["llm", "user", "system"])
    |> validate_length(:command_text, min: 10, max: 5000)
  end

  @doc """
  Changeset for completing a command.
  """
  def complete_changeset(command, attrs \\ %{}) do
    command
    |> cast(attrs, [:completed_at, :status, :time_to_complete])
    |> put_change(:status, "completed")
    |> put_change(:completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
    |> calculate_time_to_complete()
  end

  @doc """
  Changeset for dismissing a command.
  """
  def dismiss_changeset(command, attrs \\ %{}) do
    command
    |> cast(attrs, [:dismissed_at, :status])
    |> put_change(:status, "dismissed")
    |> put_change(:dismissed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  defp calculate_time_to_complete(changeset) do
    case get_field(changeset, :completed_at) do
      nil ->
        changeset

      completed_at ->
        inserted_at = get_field(changeset, :inserted_at)
        time_diff = DateTime.diff(completed_at, inserted_at, :second)
        put_change(changeset, :time_to_complete, time_diff)
    end
  end
end
