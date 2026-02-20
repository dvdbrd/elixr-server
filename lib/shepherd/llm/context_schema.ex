defmodule Shepherd.LLM.ContextSchema do
  @moduledoc """
  Defines and validates the JSONB schema for website context documents.
  This schema guides the LLM on what structure to create when analyzing websites.
  """

  @doc """
  Returns the expected schema structure for website context documents.
  This is used both for validation and as documentation for the LLM.
  """
  def schema do
    %{
      concept: :string,
      business_type: :string,
      target_destinations: :list,
      service_types: :list,
      primary_cta: :string,
      confusion: :list,
      scan_cache: :map,
      conversion_goal: :string,
      step_analysis: :map,
      bottleneck_step: :string,
      bottleneck_issue: :string
    }
  end

  @doc """
  Returns a template/example context document for the LLM to follow.
  """
  def template do
    %{
      "concept" => "One sentence describing what this website does",
      "business_type" => "travel_agency | tour_operator | booking_platform | other",
      "target_destinations" => ["Country/Region 1", "Country/Region 2"],
      "service_types" => ["tours", "flights", "hotels", "packages", "car_rental"],
      "primary_cta" => "Main call-to-action text (e.g., 'Book Now', 'Get Quote')",
      "confusion" => [
        %{
          "issue" => "What's unclear or ambiguous",
          "page" => "Which page/section (URL or description)"
        }
      ],
      "scan_cache" => %{
        "pages_analyzed" => ["https://example.com/", "https://example.com/tours"],
        "scan_date" => "2026-01-27T10:30:00Z",
        "homepage_summary" => "Brief description of homepage content"
      },
      "conversion_goal" => "What action should visitors take (e.g., 'book ski lessons', 'request quote', 'purchase tour')",
      "step_analysis" => %{
        "step_1_attention" => %{"status" => "good|weak|failing", "notes" => "Headline analysis"},
        "step_2_engagement" => %{"status" => "good|weak|failing", "notes" => "Engagement elements"},
        "step_3_comprehension" => %{"status" => "good|weak|failing", "notes" => "Clarity of offering"},
        "step_4_belief" => %{"status" => "good|weak|failing", "notes" => "Trust signals"},
        "step_5_desire" => %{"status" => "good|weak|failing", "notes" => "Benefit communication"},
        "step_6_urgency" => %{"status" => "good|weak|failing", "notes" => "Urgency triggers"},
        "step_7_intent" => %{"status" => "good|weak|failing", "notes" => "CTA clarity"},
        "step_8_action" => %{"status" => "good|weak|failing", "notes" => "Action friction"}
      },
      "bottleneck_step" => "step_3_comprehension (which step fails worst)",
      "bottleneck_issue" => "Description of why this step fails and what's missing"
    }
  end

  @doc """
  Returns detailed documentation for the LLM explaining each field.
  This gets included in the directive prompt.
  """
  def field_documentation do
    """
    ## Context Document Structure

    You must create a JSON document with the following fields:

    **concept** (string, required)
    - One clear sentence describing what this website does
    - Focus on the main value proposition
    - Example: "Online travel agency for booking tours in Southeast Asia"

    **business_type** (string, required)
    - Choose one: "travel_agency", "tour_operator", "booking_platform", "other"
    - travel_agency: Books trips for others (not organizing tours themselves)
    - tour_operator: Organizes and operates their own tours
    - booking_platform: Aggregator connecting users to providers
    - other: If none of the above fit

    **target_destinations** (array of strings, required)
    - List main countries/regions this site focuses on
    - Be specific: "Thailand" not "Asia"
    - Maximum 5 destinations
    - Empty array [] if not destination-specific

    **service_types** (array of strings, required)
    - What services they offer
    - Choose from: "tours", "flights", "hotels", "packages", "car_rental", "activities", "cruises"
    - Include all that apply
    - Empty array [] if unclear

    **primary_cta** (string, required)
    - The main call-to-action text you see on the homepage
    - Exact wording if possible
    - Example: "Book Your Adventure", "Get Free Quote", "Start Planning"
    - Empty string "" if no clear CTA

    **confusion** (array of objects, required)
    - List anything ambiguous or unclear about the website
    - Each item should have:
      - "issue": What's unclear
      - "page": Where you found it (URL or description)
    - Empty array [] if everything is clear
    - Use this to ask user questions later

    **scan_cache** (object, required)
    - Technical metadata about the scan
    - Required fields:
      - "pages_analyzed": Array of URLs you scanned
      - "scan_date": Current datetime in ISO format
      - "homepage_summary": 1-2 sentence summary of homepage

    **conversion_goal** (string, required)
    - What action should visitors take on this website?
    - Based on business type and content analysis
    - Example: "book ski lessons", "request quote", "purchase tour package"
    - Be specific - what is the PRIMARY desired action?

    **step_analysis** (object, required)
    - Analysis of the 8-step conversion ladder
    - Each step has "status" (good|weak|failing) and "notes" (what's working/missing)
    - Steps:
      - step_1_attention: Does headline grab attention and communicate value?
      - step_2_engagement: Are there visual elements that encourage exploration?
      - step_3_comprehension: Can visitors understand WHAT is being offered? (details, pricing, specifics)
      - step_4_belief: Are there trust signals? (testimonials, reviews, credentials)
      - step_5_desire: Are benefits clearly tied to visitor needs?
      - step_6_urgency: Is there reason to act now vs later?
      - step_7_intent: Is the CTA clear and visible?
      - step_8_action: Is taking action easy? (simple form, multiple contact options)

    **bottleneck_step** (string, required)
    - Which of the 8 steps has the worst performance?
    - Format: "step_3_comprehension" (use exact step name)
    - This is where most visitors likely drop off

    **bottleneck_issue** (string, required)
    - Clear description of WHY that step fails
    - What is missing or broken at that step?
    - Example: "No product descriptions with pricing - visitors can't understand what they're buying"

    ## Important Rules

    1. All fields are required - use empty values if data not available
    2. Be concise - concept should be one sentence
    3. Mark genuine confusion in the "confusion" array
    4. Only include pages you actually analyzed in scan_cache
    5. Use exact CTA wording, not paraphrased
    6. Analyze conversion flow from visitor perspective - work backwards from goal
    7. Be honest about bottleneck - identify the weakest step
    """
  end

  @doc """
  Validates a context document against the expected schema.
  Returns {:ok, context} if valid, {:error, reason} if invalid.
  """
  def validate(context) when is_map(context) do
    required_fields = [
      "concept",
      "business_type",
      "target_destinations",
      "service_types",
      "primary_cta",
      "confusion",
      "scan_cache",
      "conversion_goal",
      "step_analysis",
      "bottleneck_step",
      "bottleneck_issue"
    ]

    # Check all required fields present
    missing_fields = Enum.filter(required_fields, fn field -> !Map.has_key?(context, field) end)

    cond do
      length(missing_fields) > 0 ->
        {:error, "Missing required fields: #{Enum.join(missing_fields, ", ")}"}

      !is_binary(context["concept"]) ->
        {:error, "Field 'concept' must be a string"}

      !is_binary(context["business_type"]) ->
        {:error, "Field 'business_type' must be a string"}

      !is_list(context["target_destinations"]) ->
        {:error, "Field 'target_destinations' must be an array"}

      !is_list(context["service_types"]) ->
        {:error, "Field 'service_types' must be an array"}

      !is_binary(context["primary_cta"]) ->
        {:error, "Field 'primary_cta' must be a string"}

      !is_list(context["confusion"]) ->
        {:error, "Field 'confusion' must be an array"}

      !is_map(context["scan_cache"]) ->
        {:error, "Field 'scan_cache' must be an object"}

      !validate_scan_cache(context["scan_cache"]) ->
        {:error, "Field 'scan_cache' must contain 'pages_analyzed', 'scan_date', and 'homepage_summary'"}

      !is_binary(context["conversion_goal"]) ->
        {:error, "Field 'conversion_goal' must be a string"}

      !is_map(context["step_analysis"]) ->
        {:error, "Field 'step_analysis' must be an object"}

      !is_binary(context["bottleneck_step"]) ->
        {:error, "Field 'bottleneck_step' must be a string"}

      !is_binary(context["bottleneck_issue"]) ->
        {:error, "Field 'bottleneck_issue' must be a string"}

      true ->
        {:ok, context}
    end
  end

  def validate(_), do: {:error, "Context must be a map/object"}

  # Validate scan_cache has required nested fields
  defp validate_scan_cache(scan_cache) do
    is_map(scan_cache) &&
      Map.has_key?(scan_cache, "pages_analyzed") &&
      Map.has_key?(scan_cache, "scan_date") &&
      Map.has_key?(scan_cache, "homepage_summary") &&
      is_list(scan_cache["pages_analyzed"])
  end

  @doc """
  Merges new context with existing context intelligently.
  Used when updating an existing website context.
  """
  def merge_contexts(existing, new_context) when is_map(existing) and is_map(new_context) do
    # Merge confusion arrays (append new confusions)
    existing_confusion = Map.get(existing, "confusion", [])
    new_confusion = Map.get(new_context, "confusion", [])
    merged_confusion = existing_confusion ++ new_confusion

    # Take new values for all other fields
    Map.merge(existing, new_context)
    |> Map.put("confusion", merged_confusion)
  end

  def merge_contexts(_existing, new_context), do: new_context
end
