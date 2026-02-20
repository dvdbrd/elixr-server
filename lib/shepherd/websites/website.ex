defmodule Shepherd.Websites.Website do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "websites" do
    field :url, :string
    field :name, :string
    field :github_repo_url, :string
    field :last_scanned_at, :utc_datetime
    field :status, :string, default: "active"

    belongs_to :user, Shepherd.Accounts.User, type: :integer

    has_one :context, Shepherd.Websites.WebsiteContext
    has_many :questions, Shepherd.Websites.UserQuestion

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(website, attrs) do
    website
    |> cast(attrs, [:user_id, :url, :name, :github_repo_url, :last_scanned_at, :status])
    |> validate_required([:user_id, :url])
    |> validate_length(:url, max: 500)
    |> validate_length(:name, max: 255)
    |> validate_length(:github_repo_url, max: 500)
    |> validate_inclusion(:status, ["active", "inactive", "scanning", "error", "pending_analysis", "analyzing", "analyzed"])
    |> foreign_key_constraint(:user_id)
  end
end
