defmodule Shepherd.LLM.ContextSchemaTest do
  use Shepherd.DataCase, async: true

  alias Shepherd.LLM.ContextSchema

  # A fully valid context document used in multiple tests
  @valid_context %{
    "concept" => "Online travel agency specialising in ski tours",
    "business_type" => "tour_operator",
    "target_destinations" => ["Georgia", "Austria"],
    "service_types" => ["tours", "hotels"],
    "primary_cta" => "Book Now",
    "confusion" => [],
    "scan_cache" => %{
      "pages_analyzed" => ["https://example.com/"],
      "scan_date" => "2026-01-01T10:00:00Z",
      "homepage_summary" => "Homepage overview of ski tours."
    },
    "conversion_goal" => "book a ski lesson package",
    "step_analysis" => %{
      "step_1_attention" => %{"status" => "good", "notes" => "Strong headline"}
    },
    "bottleneck_step" => "step_3_comprehension",
    "bottleneck_issue" => "Pricing is unclear for visitors"
  }

  # ---------------------------------------------------------------------------
  # schema/0
  # ---------------------------------------------------------------------------

  describe "schema/0" do
    test "returns a map with the expected field keys" do
      s = ContextSchema.schema()

      assert is_map(s)

      expected_keys = [
        :concept,
        :business_type,
        :target_destinations,
        :service_types,
        :primary_cta,
        :confusion,
        :scan_cache,
        :conversion_goal,
        :step_analysis,
        :bottleneck_step,
        :bottleneck_issue
      ]

      for key <- expected_keys do
        assert Map.has_key?(s, key), "Expected key #{key} not found in schema"
      end
    end

    test "maps fields to their expected types" do
      s = ContextSchema.schema()

      assert s[:concept] == :string
      assert s[:target_destinations] == :list
      assert s[:scan_cache] == :map
      assert s[:confusion] == :list
      assert s[:step_analysis] == :map
    end
  end

  # ---------------------------------------------------------------------------
  # template/0
  # ---------------------------------------------------------------------------

  describe "template/0" do
    test "returns a map with all required string keys" do
      t = ContextSchema.template()

      assert is_map(t)

      required_keys = [
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

      for key <- required_keys do
        assert Map.has_key?(t, key), "Expected key #{key} not found in template"
      end
    end

    test "scan_cache contains required nested keys" do
      t = ContextSchema.template()
      scan_cache = t["scan_cache"]

      assert is_map(scan_cache)
      assert Map.has_key?(scan_cache, "pages_analyzed")
      assert Map.has_key?(scan_cache, "scan_date")
      assert Map.has_key?(scan_cache, "homepage_summary")
    end
  end

  # ---------------------------------------------------------------------------
  # validate/1
  # ---------------------------------------------------------------------------

  describe "validate/1" do
    test "returns ok for a valid context document" do
      assert {:ok, _context} = ContextSchema.validate(@valid_context)
    end

    test "returns error when required field is missing" do
      invalid = Map.delete(@valid_context, "concept")

      assert {:error, message} = ContextSchema.validate(invalid)
      assert message =~ "Missing required fields"
      assert message =~ "concept"
    end

    test "returns error when concept is not a string" do
      invalid = Map.put(@valid_context, "concept", 42)

      assert {:error, message} = ContextSchema.validate(invalid)
      assert message =~ "concept"
    end

    test "returns error when target_destinations is not a list" do
      invalid = Map.put(@valid_context, "target_destinations", "Georgia")

      assert {:error, message} = ContextSchema.validate(invalid)
      assert message =~ "target_destinations"
    end

    test "returns error when scan_cache is missing required nested fields" do
      invalid =
        Map.put(@valid_context, "scan_cache", %{
          "scan_date" => "2026-01-01T10:00:00Z"
        })

      assert {:error, message} = ContextSchema.validate(invalid)
      assert message =~ "scan_cache"
    end

    test "returns error when input is not a map" do
      assert {:error, message} = ContextSchema.validate("not a map")
      assert message =~ "map"
    end

    test "returns error when confusion is not a list" do
      invalid = Map.put(@valid_context, "confusion", "should be a list")

      assert {:error, message} = ContextSchema.validate(invalid)
      assert message =~ "confusion"
    end
  end

  # ---------------------------------------------------------------------------
  # merge_contexts/2
  # ---------------------------------------------------------------------------

  describe "merge_contexts/2" do
    test "scalar fields from new_context take precedence" do
      existing = @valid_context
      new_ctx = Map.put(@valid_context, "concept", "Updated concept here")

      merged = ContextSchema.merge_contexts(existing, new_ctx)
      assert merged["concept"] == "Updated concept here"
    end

    test "confusion arrays are appended, not replaced" do
      existing =
        Map.put(@valid_context, "confusion", [
          %{"issue" => "Existing issue", "page" => "/home"}
        ])

      new_ctx =
        Map.put(@valid_context, "confusion", [
          %{"issue" => "New issue", "page" => "/about"}
        ])

      merged = ContextSchema.merge_contexts(existing, new_ctx)
      assert length(merged["confusion"]) == 2

      issues = Enum.map(merged["confusion"], & &1["issue"])
      assert "Existing issue" in issues
      assert "New issue" in issues
    end

    test "empty confusion array in new_context does not remove existing confusions" do
      existing =
        Map.put(@valid_context, "confusion", [
          %{"issue" => "Old issue", "page" => "/page"}
        ])

      new_ctx = Map.put(@valid_context, "confusion", [])

      merged = ContextSchema.merge_contexts(existing, new_ctx)
      assert length(merged["confusion"]) == 1
    end

    test "when existing is not a map, returns new_context unchanged" do
      new_ctx = @valid_context
      merged = ContextSchema.merge_contexts("not a map", new_ctx)
      assert merged == new_ctx
    end
  end

  # ---------------------------------------------------------------------------
  # field_documentation/0
  # ---------------------------------------------------------------------------

  describe "field_documentation/0" do
    test "returns a non-empty string" do
      docs = ContextSchema.field_documentation()
      assert is_binary(docs)
      refute docs == ""
    end

    test "mentions all required field names" do
      docs = ContextSchema.field_documentation()

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

      for field <- required_fields do
        assert docs =~ field, "Field '#{field}' not mentioned in documentation"
      end
    end
  end
end
