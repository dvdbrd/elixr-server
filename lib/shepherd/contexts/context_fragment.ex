defmodule Shepherd.Contexts.ContextFragment do
  @moduledoc """
  Schema for context fragments - optimized storage for LLM efficiency.

  Instead of storing one large JSONB document, context is split into fragments
  that can be loaded independently. This allows LLM to fetch only what it needs,
  reducing parsing time and token usage.

  ## Fragment Types

  - `concept` - High-level understanding (changes rarely)
  - `active_tasks` - Current priorities (changes often)
  - `behavioral_notes` - User interaction patterns (changes often)
  - `scan_cache` - Website scan results (large, changes rarely)
  - `confusion` - Ambiguous information requiring clarification
  - `short_term_memory` - Recent insights and decisions
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "context_fragments" do
    field :user_id, :integer

    # Polymorphic association
    field :entity_type, :string
    field :entity_id, :binary_id

    # Fragment type
    field :fragment_type, :string

    # Data (keep small and focused)
    field :content, :map, default: %{}

    # Metadata
    field :updated_by, :string, default: "system"
    field :access_frequency, :string, default: "medium"

    field :updated_at, :utc_datetime
  end

  @valid_fragment_types [
    "concept",
    "active_tasks",
    "behavioral_notes",
    "scan_cache",
    "confusion",
    "short_term_memory"
  ]

  @valid_access_frequencies ["high", "medium", "low"]

  @doc false
  def changeset(fragment, attrs) do
    fragment
    |> cast(attrs, [
      :user_id,
      :entity_type,
      :entity_id,
      :fragment_type,
      :content,
      :updated_by,
      :access_frequency,
      :updated_at
    ])
    |> validate_required([:user_id, :entity_type, :entity_id, :fragment_type, :content])
    |> validate_inclusion(:fragment_type, @valid_fragment_types)
    |> validate_inclusion(:access_frequency, @valid_access_frequencies)
    |> validate_inclusion(:updated_by, ["llm", "user", "system"])
    |> unique_constraint([:entity_type, :entity_id, :fragment_type],
      name: :context_fragments_unique
    )
    |> maybe_set_updated_at()
  end

  defp maybe_set_updated_at(changeset) do
    put_change(changeset, :updated_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  @doc """
  Get recommended access frequency based on fragment type.
  """
  def access_frequency_for_type("concept"), do: "low"
  def access_frequency_for_type("scan_cache"), do: "low"
  def access_frequency_for_type("active_tasks"), do: "high"
  def access_frequency_for_type("behavioral_notes"), do: "high"
  def access_frequency_for_type("short_term_memory"), do: "medium"
  def access_frequency_for_type("confusion"), do: "medium"
  def access_frequency_for_type(_), do: "medium"

  @doc """
  Determine if fragment should be cached based on access frequency.
  """
  def should_cache?(%__MODULE__{access_frequency: "high"}), do: true
  def should_cache?(%__MODULE__{access_frequency: "medium"}), do: true
  def should_cache?(_), do: false

  @doc """
  Get fragment size category (for monitoring).
  """
  def size_category(%__MODULE__{content: content}) do
    json_size = :erlang.byte_size(:erlang.term_to_binary(content))

    cond do
      json_size < 1_000 -> :small
      json_size < 10_000 -> :medium
      json_size < 100_000 -> :large
      true -> :very_large
    end
  end
end
