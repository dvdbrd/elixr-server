defmodule Shepherd.LLM.UserCommand do
  @moduledoc """
  Schema alias for commands table, used by HQ LiveViews.
  Mirrors Shepherd.Commands.Command with identical fields.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "commands" do
    field :user_id, :integer
    field :entity_type, :string
    field :entity_id, :binary_id
    field :command_text, :string
    field :urgency, :string, default: "medium"
    field :status, :string, default: "pending"
    field :created_by, :string, default: "llm"
    field :llm_reasoning, :string
    field :deadline, :utc_datetime
    field :completed_at, :utc_datetime
    field :dismissed_at, :utc_datetime
    field :time_to_complete, :integer
    field :reminded_count, :integer, default: 0

    timestamps(type: :utc_datetime)
  end

  def changeset(command, attrs) do
    command
    |> cast(attrs, [:user_id, :entity_type, :entity_id, :command_text, :urgency, :status])
    |> validate_required([:user_id, :command_text])
  end
end
