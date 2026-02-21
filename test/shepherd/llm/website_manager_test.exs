defmodule Shepherd.LLM.WebsiteManagerTest do
  use Shepherd.DataCase, async: true

  alias Shepherd.LLM.WebsiteManager

  import Shepherd.AccountsFixtures
  import Shepherd.WebsitesFixtures

  # ---------------------------------------------------------------------------
  # get_context/2
  # ---------------------------------------------------------------------------

  describe "get_context/2" do
    test "returns the context document when it exists" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})
      website_context_fixture(%{website_id: website.id})

      assert {:ok, context} = WebsiteManager.get_context(user.id, website.id)
      assert is_map(context)
      assert Map.has_key?(context, "concept")
    end

    test "returns error when context does not exist for the website" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:error, :not_found} = WebsiteManager.get_context(user.id, website.id)
    end

    test "returns error when user does not own the website" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})
      website_context_fixture(%{website_id: website.id})

      assert {:error, :not_found} = WebsiteManager.get_context(user2.id, website.id)
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} = WebsiteManager.get_context(nil, Ecto.UUID.generate())
    end
  end

  # ---------------------------------------------------------------------------
  # update_context/3
  # ---------------------------------------------------------------------------

  describe "update_context/3" do
    test "creates a new context when none exists" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})
      new_doc = %{"concept" => "A new concept", "business_type" => "other"}

      assert {:ok, context} = WebsiteManager.update_context(user.id, website.id, new_doc)
      assert context.context_document["concept"] == "A new concept"
    end

    test "updates an existing context" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})
      website_context_fixture(%{website_id: website.id})

      updated_doc = %{"concept" => "Updated concept", "business_type" => "tour_operator"}
      assert {:ok, context} = WebsiteManager.update_context(user.id, website.id, updated_doc)
      assert context.context_document["concept"] == "Updated concept"
    end

    test "returns error when user does not own the website" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})

      assert {:error, :not_found} =
               WebsiteManager.update_context(user2.id, website.id, %{"concept" => "x"})
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.update_context(nil, Ecto.UUID.generate(), %{})
    end

    test "returns error when new_jsonb is not a map" do
      user = user_fixture()

      assert {:error, :invalid_jsonb} =
               WebsiteManager.update_context(user.id, Ecto.UUID.generate(), "not a map")
    end
  end

  # ---------------------------------------------------------------------------
  # ask_question/4
  # ---------------------------------------------------------------------------

  describe "ask_question/4" do
    test "creates a question for a website owned by the user" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:ok, question} =
               WebsiteManager.ask_question(
                 user.id,
                 website.id,
                 "What is your primary goal?",
                 ["Sales", "Leads", "Signups"]
               )

      assert question.status == "pending"
      assert question.question_text == "What is your primary goal?"
      assert question.user_id == user.id
    end

    test "returns error when user does not own the website" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})

      assert {:error, :not_found} =
               WebsiteManager.ask_question(user2.id, website.id, "Some question?", ["A", "B"])
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.ask_question(nil, Ecto.UUID.generate(), "Question?", ["A"])
    end
  end

  # ---------------------------------------------------------------------------
  # get_unanswered_questions/2
  # ---------------------------------------------------------------------------

  describe "get_unanswered_questions/2" do
    test "returns only pending questions for the website" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      # Create a pending question
      user_question_fixture(%{
        user_id: user.id,
        entity_id: website.id,
        website_id: website.id
      })

      # Create an answered question — should not appear
      user_question_fixture(%{
        user_id: user.id,
        entity_id: website.id,
        website_id: website.id,
        status: "answered"
      })

      assert {:ok, questions} = WebsiteManager.get_unanswered_questions(user.id, website.id)
      assert length(questions) == 1
      assert hd(questions).status == "pending"
    end

    test "returns empty list when no pending questions exist" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:ok, []} = WebsiteManager.get_unanswered_questions(user.id, website.id)
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.get_unanswered_questions(nil, Ecto.UUID.generate())
    end
  end

  # ---------------------------------------------------------------------------
  # record_answer/3
  # ---------------------------------------------------------------------------

  describe "record_answer/3" do
    test "records an answer and sets status to answered" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      question =
        user_question_fixture(%{
          user_id: user.id,
          entity_id: website.id,
          website_id: website.id
        })

      assert {:ok, updated} = WebsiteManager.record_answer(user.id, question.id, "My answer")
      assert updated.status == "answered"
      assert updated.answer["answer"] == "My answer"
    end

    test "returns error when user does not own the question" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})

      question =
        user_question_fixture(%{
          user_id: user1.id,
          entity_id: website.id,
          website_id: website.id
        })

      assert {:error, :not_found} = WebsiteManager.record_answer(user2.id, question.id, "x")
    end

    test "returns error when answer is nil" do
      user = user_fixture()

      assert {:error, :invalid_answer} =
               WebsiteManager.record_answer(user.id, Ecto.UUID.generate(), nil)
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.record_answer(nil, Ecto.UUID.generate(), "answer")
    end
  end

  # ---------------------------------------------------------------------------
  # dismiss_question/2
  # ---------------------------------------------------------------------------

  describe "dismiss_question/2" do
    test "sets question status to dismissed" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      question =
        user_question_fixture(%{
          user_id: user.id,
          entity_id: website.id,
          website_id: website.id
        })

      assert {:ok, updated} = WebsiteManager.dismiss_question(user.id, question.id)
      assert updated.status == "dismissed"
    end

    test "returns error when user does not own the question" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})

      question =
        user_question_fixture(%{
          user_id: user1.id,
          entity_id: website.id,
          website_id: website.id
        })

      assert {:error, :not_found} = WebsiteManager.dismiss_question(user2.id, question.id)
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.dismiss_question(nil, Ecto.UUID.generate())
    end
  end

  # ---------------------------------------------------------------------------
  # ask_question_polymorphic/6
  # ---------------------------------------------------------------------------

  describe "ask_question_polymorphic/6" do
    test "creates a question with polymorphic entity type" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      assert {:ok, question} =
               WebsiteManager.ask_question_polymorphic(
                 user.id,
                 "command",
                 entity_id,
                 "Have you completed this task?",
                 ["Yes", "No", "In progress"]
               )

      assert question.entity_type == "command"
      assert question.entity_id == entity_id
      assert question.user_id == user.id
      assert question.status == "pending"
    end

    test "also sets website_id when entity_type is website" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:ok, question} =
               WebsiteManager.ask_question_polymorphic(
                 user.id,
                 "website",
                 website.id,
                 "What do visitors see first?",
                 ["Hero image", "Text", "Video"]
               )

      assert question.entity_type == "website"
      assert question.website_id == website.id
    end

    test "accepts optional question_type and severity via opts" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      assert {:ok, question} =
               WebsiteManager.ask_question_polymorphic(
                 user.id,
                 "command",
                 entity_id,
                 "Is this complaint resolved?",
                 ["Yes", "No"],
                 question_type: "complaint",
                 severity: "warning"
               )

      assert question.question_type == "complaint"
      assert question.severity == "warning"
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.ask_question_polymorphic(
                 nil,
                 "website",
                 Ecto.UUID.generate(),
                 "Question?",
                 ["A"]
               )
    end
  end

  # ---------------------------------------------------------------------------
  # expire_old_questions/0
  # ---------------------------------------------------------------------------

  describe "expire_old_questions/0" do
    test "expires pending questions whose expires_at is in the past" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      past = DateTime.utc_now() |> DateTime.add(-10, :second) |> DateTime.truncate(:second)

      user_question_fixture(%{
        user_id: user.id,
        entity_id: website.id,
        website_id: website.id,
        expires_at: past
      })

      assert {:ok, count} = WebsiteManager.expire_old_questions()
      assert count >= 1
    end

    test "does not expire questions with no expires_at" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      user_question_fixture(%{
        user_id: user.id,
        entity_id: website.id,
        website_id: website.id
      })

      assert {:ok, _count} = WebsiteManager.expire_old_questions()

      assert {:ok, questions} = WebsiteManager.get_unanswered_questions(user.id, website.id)
      assert length(questions) == 1
    end
  end

  # ---------------------------------------------------------------------------
  # get_question_stats/3
  # ---------------------------------------------------------------------------

  describe "get_question_stats/3" do
    test "returns stats map with question counts by type and status" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      user_question_fixture(%{
        user_id: user.id,
        entity_id: website.id,
        website_id: website.id,
        question_type: "onboarding",
        status: "pending"
      })

      user_question_fixture(%{
        user_id: user.id,
        entity_id: website.id,
        website_id: website.id,
        question_type: "onboarding",
        status: "answered"
      })

      assert {:ok, stats} = WebsiteManager.get_question_stats(user.id, "website", website.id)
      assert is_map(stats)
      assert get_in(stats, ["onboarding", "pending"]) == 1
      assert get_in(stats, ["onboarding", "answered"]) == 1
    end

    test "returns empty stats map when no questions exist" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:ok, stats} = WebsiteManager.get_question_stats(user.id, "website", website.id)
      assert stats == %{}
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.get_question_stats(nil, "website", Ecto.UUID.generate())
    end
  end

  # ---------------------------------------------------------------------------
  # get_website_info/2
  # ---------------------------------------------------------------------------

  describe "get_website_info/2" do
    test "returns a map with website metadata when found" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:ok, info} = WebsiteManager.get_website_info(user.id, website.id)
      assert info.id == website.id
      assert info.url == website.url
      assert info.name == website.name
      assert info.status == website.status
      assert info.user_id == user.id
    end

    test "returns error when website not found or not owned by user" do
      user = user_fixture()
      other_user = user_fixture()
      website = website_fixture(%{user_id: other_user.id})

      assert {:error, :not_found} = WebsiteManager.get_website_info(user.id, website.id)
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.get_website_info(nil, Ecto.UUID.generate())
    end
  end

  # ---------------------------------------------------------------------------
  # update_website_status/3
  # ---------------------------------------------------------------------------

  describe "update_website_status/3" do
    test "updates to a valid status" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id, status: "pending_analysis"})

      assert {:ok, updated} =
               WebsiteManager.update_website_status(user.id, website.id, "analyzed")

      assert updated.status == "analyzed"
    end

    test "sets last_scanned_at when status is set to active" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id, status: "analyzed"})

      assert {:ok, updated} = WebsiteManager.update_website_status(user.id, website.id, "active")
      assert updated.status == "active"
      refute is_nil(updated.last_scanned_at)
    end

    test "returns error for an invalid status" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:error, :invalid_status} =
               WebsiteManager.update_website_status(user.id, website.id, "banana")
    end

    test "returns error when user does not own the website" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})

      assert {:error, :not_found} =
               WebsiteManager.update_website_status(user2.id, website.id, "active")
    end

    test "returns error when user_id is nil" do
      assert {:error, :user_id_required} =
               WebsiteManager.update_website_status(nil, Ecto.UUID.generate(), "active")
    end
  end

  # ---------------------------------------------------------------------------
  # create_website_with_scan/2
  # ---------------------------------------------------------------------------

  describe "create_website_with_scan/2" do
    test "creates a website with pending_analysis status" do
      user = user_fixture()

      attrs = %{
        user_id: user.id,
        url: "https://newscan-#{System.unique_integer([:positive])}.com",
        name: "New Scan Website"
      }

      assert {:ok, website} = WebsiteManager.create_website_with_scan(attrs)
      assert website.status == "pending_analysis"
      assert website.user_id == user.id
      assert website.url == attrs.url
    end

    test "returns changeset error when required attrs are missing" do
      assert {:error, changeset} = WebsiteManager.create_website_with_scan(%{})
      assert changeset.errors != []
    end
  end
end
