defmodule Shepherd.LLM.FeedbackManagerTest do
  use Shepherd.DataCase, async: true

  alias Shepherd.LLM.FeedbackManager

  import Shepherd.AccountsFixtures
  import Shepherd.FeedbackFixtures

  # ---------------------------------------------------------------------------
  # get_active_feedback/1
  # ---------------------------------------------------------------------------

  describe "get_active_feedback/1" do
    test "returns active feedback for the user" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, status: "active"})

      result = FeedbackManager.get_active_feedback(user.id)
      assert length(result) == 1
      assert hd(result).status == "active"
    end

    test "excludes acknowledged and dismissed feedback" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, status: "acknowledged"})
      feedback_fixture(%{user_id: user.id, status: "dismissed"})

      result = FeedbackManager.get_active_feedback(user.id)
      assert result == []
    end

    test "excludes feedback whose expires_at is in the past" do
      user = user_fixture()
      past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)
      feedback_fixture(%{user_id: user.id, status: "active", expires_at: past})

      result = FeedbackManager.get_active_feedback(user.id)
      assert result == []
    end

    test "returns empty list when user has no active feedback" do
      user = user_fixture()
      assert FeedbackManager.get_active_feedback(user.id) == []
    end
  end

  # ---------------------------------------------------------------------------
  # get_feedback_by_type/2
  # ---------------------------------------------------------------------------

  describe "get_feedback_by_type/2" do
    test "returns only active feedback matching the given type" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, feedback_type: "daily_summary"})
      feedback_fixture(%{user_id: user.id, feedback_type: "encouragement"})

      result = FeedbackManager.get_feedback_by_type(user.id, "daily_summary")
      assert length(result) == 1
      assert hd(result).feedback_type == "daily_summary"
    end

    test "returns empty list when no feedback matches the type" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, feedback_type: "encouragement"})

      result = FeedbackManager.get_feedback_by_type(user.id, "weekly_summary")
      assert result == []
    end
  end

  # ---------------------------------------------------------------------------
  # get_all_feedback/2
  # ---------------------------------------------------------------------------

  describe "get_all_feedback/2" do
    test "returns feedback of all statuses" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, status: "active"})
      feedback_fixture(%{user_id: user.id, status: "acknowledged"})
      feedback_fixture(%{user_id: user.id, status: "dismissed"})

      result = FeedbackManager.get_all_feedback(user.id)
      assert length(result) == 3
    end

    test "respects the limit parameter" do
      user = user_fixture()
      for _ <- 1..5, do: feedback_fixture(%{user_id: user.id})

      result = FeedbackManager.get_all_feedback(user.id, 3)
      assert length(result) == 3
    end

    test "returns empty list when user has no feedback" do
      user = user_fixture()
      assert FeedbackManager.get_all_feedback(user.id) == []
    end
  end

  # ---------------------------------------------------------------------------
  # get_feedback_stats/1
  # ---------------------------------------------------------------------------

  describe "get_feedback_stats/1" do
    test "returns correct counts for active, critical, and warning feedback" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, status: "active", severity: "critical"})
      feedback_fixture(%{user_id: user.id, status: "active", severity: "warning"})
      feedback_fixture(%{user_id: user.id, status: "active", severity: "info"})
      feedback_fixture(%{user_id: user.id, status: "acknowledged", severity: "critical"})

      stats = FeedbackManager.get_feedback_stats(user.id)

      assert stats.total_active == 3
      assert stats.critical == 1
      assert stats.warning == 1
    end

    test "returns zero counts when user has no feedback" do
      user = user_fixture()
      stats = FeedbackManager.get_feedback_stats(user.id)

      assert stats == %{total_active: 0, critical: 0, warning: 0}
    end
  end

  # ---------------------------------------------------------------------------
  # create_feedback/1
  # ---------------------------------------------------------------------------

  describe "create_feedback/1" do
    test "creates feedback with valid attributes" do
      user = user_fixture()

      attrs = %{
        user_id: user.id,
        feedback_type: "daily_summary",
        severity: "info",
        tone: "neutral",
        title: "Daily Progress Report",
        message: "You completed 3 tasks and improved your conversion rate."
      }

      assert {:ok, feedback} = FeedbackManager.create_feedback(attrs)
      assert feedback.user_id == user.id
      assert feedback.status == "active"
    end

    test "returns error when user_id is missing" do
      assert {:error, :user_id_required} =
               FeedbackManager.create_feedback(%{
                 feedback_type: "daily_summary",
                 title: "No User Feedback",
                 message: "This should fail without a user."
               })
    end

    test "returns changeset error for invalid feedback_type" do
      user = user_fixture()

      assert {:error, changeset} =
               FeedbackManager.create_feedback(%{
                 user_id: user.id,
                 feedback_type: "invalid_type",
                 title: "Some title here",
                 message: "Some message here that is long enough."
               })

      assert changeset.errors[:feedback_type] != nil
    end
  end

  # ---------------------------------------------------------------------------
  # acknowledge_feedback/2
  # ---------------------------------------------------------------------------

  describe "acknowledge_feedback/2" do
    test "sets status to acknowledged and sets acknowledged_at" do
      user = user_fixture()
      feedback = feedback_fixture(%{user_id: user.id})

      assert {:ok, updated} = FeedbackManager.acknowledge_feedback(user.id, feedback.id)
      assert updated.status == "acknowledged"
      refute is_nil(updated.acknowledged_at)
    end

    test "returns error when feedback does not belong to the user" do
      user = user_fixture()
      other_user = user_fixture()
      feedback = feedback_fixture(%{user_id: other_user.id})

      assert {:error, :not_found} = FeedbackManager.acknowledge_feedback(user.id, feedback.id)
    end
  end

  # ---------------------------------------------------------------------------
  # dismiss_feedback/2
  # ---------------------------------------------------------------------------

  describe "dismiss_feedback/2" do
    test "sets status to dismissed and sets dismissed_at" do
      user = user_fixture()
      feedback = feedback_fixture(%{user_id: user.id})

      assert {:ok, updated} = FeedbackManager.dismiss_feedback(user.id, feedback.id)
      assert updated.status == "dismissed"
      refute is_nil(updated.dismissed_at)
    end

    test "returns error when feedback does not belong to the user" do
      user = user_fixture()
      other_user = user_fixture()
      feedback = feedback_fixture(%{user_id: other_user.id})

      assert {:error, :not_found} = FeedbackManager.dismiss_feedback(user.id, feedback.id)
    end
  end

  # ---------------------------------------------------------------------------
  # expire_old_feedback/0
  # ---------------------------------------------------------------------------

  describe "expire_old_feedback/0" do
    test "expires active feedback past its expires_at date" do
      user = user_fixture()
      past = DateTime.utc_now() |> DateTime.add(-60, :second) |> DateTime.truncate(:second)
      feedback_fixture(%{user_id: user.id, status: "active", expires_at: past})

      {:ok, count} = FeedbackManager.expire_old_feedback()
      assert count >= 1
    end

    test "does not expire active feedback with no expiration date" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id, status: "active"})

      {:ok, count} = FeedbackManager.expire_old_feedback()
      assert count == 0
    end

    test "does not expire future-dated feedback" do
      user = user_fixture()
      future = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.truncate(:second)
      feedback_fixture(%{user_id: user.id, status: "active", expires_at: future})

      {:ok, count} = FeedbackManager.expire_old_feedback()
      assert count == 0
    end
  end

  # ---------------------------------------------------------------------------
  # delete_all_user_feedback/1
  # ---------------------------------------------------------------------------

  describe "delete_all_user_feedback/1" do
    test "deletes all feedback for the given user" do
      user = user_fixture()
      feedback_fixture(%{user_id: user.id})
      feedback_fixture(%{user_id: user.id})

      {count, _} = FeedbackManager.delete_all_user_feedback(user.id)
      assert count == 2

      assert FeedbackManager.get_all_feedback(user.id) == []
    end

    test "does not delete feedback belonging to a different user" do
      user1 = user_fixture()
      user2 = user_fixture()
      feedback_fixture(%{user_id: user1.id})
      feedback_fixture(%{user_id: user2.id})

      {_count, _} = FeedbackManager.delete_all_user_feedback(user1.id)

      # user2's feedback is untouched
      assert length(FeedbackManager.get_all_feedback(user2.id)) == 1
    end
  end
end
