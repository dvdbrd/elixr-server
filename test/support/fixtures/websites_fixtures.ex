defmodule Shepherd.WebsitesFixtures do
  @moduledoc """
  Test helpers for creating website-related entities.
  """

  alias Shepherd.Repo
  alias Shepherd.Websites.{Website, WebsiteContext, UserQuestion}

  def valid_website_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      url: "https://example-#{System.unique_integer([:positive])}.com",
      name: "Test Website #{System.unique_integer([:positive])}",
      status: "active",
      user_id: nil
    })
  end

  def website_fixture(attrs \\ %{}) do
    attrs = valid_website_attributes(attrs)

    if is_nil(attrs.user_id) do
      raise "website_fixture requires :user_id"
    end

    %Website{}
    |> Website.changeset(Map.take(attrs, [:user_id, :url, :name, :status]))
    |> Repo.insert!()
  end

  def valid_website_context_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      context_document: %{
        "concept" => "Test website concept",
        "business_type" => "other",
        "target_destinations" => ["US"],
        "service_types" => ["tours"],
        "primary_cta" => "Sign Up Now",
        "confusion" => [],
        "scan_cache" => %{
          "pages_analyzed" => ["https://example.com"],
          "scan_date" => DateTime.utc_now() |> DateTime.to_iso8601(),
          "homepage_summary" => "Test homepage"
        },
        "conversion_goal" => "Sign up for service",
        "step_analysis" => %{
          "step_1_attention" => %{"status" => "good", "notes" => ""},
          "step_2_interest" => %{"status" => "good", "notes" => ""},
          "step_3_comprehension" => %{"status" => "weak", "notes" => ""},
          "step_4_credibility" => %{"status" => "good", "notes" => ""},
          "step_5_motivation" => %{"status" => "good", "notes" => ""},
          "step_6_confidence" => %{"status" => "good", "notes" => ""},
          "step_7_commitment" => %{"status" => "good", "notes" => ""},
          "step_8_action" => %{"status" => "good", "notes" => ""}
        },
        "bottleneck_step" => "step_3_comprehension",
        "bottleneck_issue" => "Users struggle to understand the offering"
      },
      website_id: nil,
      updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    })
  end

  def website_context_fixture(attrs \\ %{}) do
    attrs = valid_website_context_attributes(attrs)

    if is_nil(attrs.website_id) do
      raise "website_context_fixture requires :website_id"
    end

    %WebsiteContext{}
    |> WebsiteContext.changeset(Map.take(attrs, [:website_id, :context_document, :updated_at]))
    |> Repo.insert!()
  end

  def valid_user_question_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      user_id: nil,
      entity_type: "website",
      entity_id: Ecto.UUID.generate(),
      question_text: "What is the primary conversion goal of this website?",
      options: %{"choices" => ["Sales", "Leads", "Signups", "Other"]},
      question_type: "onboarding",
      severity: "info",
      status: "pending"
    })
  end

  def user_question_fixture(attrs \\ %{}) do
    attrs = valid_user_question_attributes(attrs)

    if is_nil(attrs.user_id) do
      raise "user_question_fixture requires :user_id"
    end

    %UserQuestion{}
    |> UserQuestion.changeset(Map.take(attrs, [
      :user_id, :entity_type, :entity_id, :question_text,
      :options, :question_type, :severity, :status, :website_id, :expires_at
    ]))
    |> Repo.insert!()
  end
end
