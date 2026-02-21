defmodule Shepherd.Contexts do
  @moduledoc """
  Context module for managing context fragments.
  Provides CRUD operations for the fragment-based context storage system.
  """

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.Contexts.ContextFragment

  @doc """
  Get a specific fragment by entity and fragment type.
  Returns nil if not found.
  """
  def get_fragment(user_id, entity_type, entity_id, fragment_type) do
    Repo.one(
      from f in ContextFragment,
        where:
          f.user_id == ^user_id and
            f.entity_type == ^entity_type and
            f.entity_id == ^entity_id and
            f.fragment_type == ^fragment_type
    )
  end

  @doc """
  Get all fragments for a given entity, ordered by fragment type.
  """
  def get_all_fragments(user_id, entity_type, entity_id) do
    Repo.all(
      from f in ContextFragment,
        where:
          f.user_id == ^user_id and
            f.entity_type == ^entity_type and
            f.entity_id == ^entity_id,
        order_by: [asc: f.fragment_type]
    )
  end

  @doc """
  Get fragments by access frequency (e.g., only "high" frequency fragments).
  """
  def get_fragments_by_frequency(user_id, entity_type, entity_id, frequency) do
    Repo.all(
      from f in ContextFragment,
        where:
          f.user_id == ^user_id and
            f.entity_type == ^entity_type and
            f.entity_id == ^entity_id and
            f.access_frequency == ^frequency,
        order_by: [asc: f.fragment_type]
    )
  end

  @doc """
  Upsert a fragment. If one already exists for the entity+fragment_type combo,
  it updates the content. Otherwise creates a new one.
  Uses the unique constraint on (entity_type, entity_id, fragment_type).
  """
  def upsert_fragment(attrs) do
    %ContextFragment{}
    |> ContextFragment.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:content, :updated_by, :access_frequency, :updated_at]},
      conflict_target: [:entity_type, :entity_id, :fragment_type]
    )
  end

  @doc """
  Update a specific fragment's content.
  """
  def update_fragment(%ContextFragment{} = fragment, attrs) do
    fragment
    |> ContextFragment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete a specific fragment.
  """
  def delete_fragment(%ContextFragment{} = fragment) do
    Repo.delete(fragment)
  end

  @doc """
  Delete all fragments for a given entity.
  Returns {count, nil}.
  """
  def delete_all_fragments(user_id, entity_type, entity_id) do
    from(f in ContextFragment,
      where:
        f.user_id == ^user_id and
          f.entity_type == ^entity_type and
          f.entity_id == ^entity_id
    )
    |> Repo.delete_all()
  end

  @doc """
  Build a full context map from all fragments for an entity.
  Returns a map of %{fragment_type => content}.
  """
  def build_context(user_id, entity_type, entity_id) do
    fragments = get_all_fragments(user_id, entity_type, entity_id)

    context =
      fragments
      |> Enum.map(fn f -> {f.fragment_type, f.content} end)
      |> Map.new()

    {:ok, context}
  end

  @doc """
  Get fragment count for a given entity.
  """
  def fragment_count(user_id, entity_type, entity_id) do
    Repo.one(
      from f in ContextFragment,
        where:
          f.user_id == ^user_id and
            f.entity_type == ^entity_type and
            f.entity_id == ^entity_id,
        select: count(f.id)
    )
  end
end
