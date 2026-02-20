defmodule Shepherd.Websites.WebsiteContext do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "website_contexts" do
    field :context_document, :map, default: %{}
    field :updated_at, :utc_datetime

    belongs_to :website, Shepherd.Websites.Website
  end

  @doc false
  def changeset(website_context, attrs) do
    website_context
    |> cast(attrs, [:website_id, :context_document, :updated_at])
    |> validate_required([:website_id, :context_document])
    |> unique_constraint(:website_id)
    |> foreign_key_constraint(:website_id)
  end

  @doc """
  Initialize a new context document with default structure
  """
  def default_context_document do
    %{
      "concept" => "",
      "confusion" => [],
      "short_term_memory" => "",
      "scan_cache" => %{},
      "active_questions" => []
    }
  end
end
