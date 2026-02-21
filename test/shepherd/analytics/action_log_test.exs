defmodule Shepherd.Analytics.ActionLogTest do
  use Shepherd.DataCase, async: true

  alias Shepherd.Analytics.ActionLog

  import Shepherd.AccountsFixtures

  # ---------------------------------------------------------------------------
  # ActionLog.changeset/2
  # ---------------------------------------------------------------------------

  describe "changeset/2" do
    test "valid changeset with all required fields" do
      attrs = %{
        user_id: 1,
        action_type: "command_completed",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      changeset = ActionLog.changeset(%ActionLog{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset when user_id is missing" do
      attrs = %{
        action_type: "command_completed",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      changeset = ActionLog.changeset(%ActionLog{}, attrs)
      refute changeset.valid?
      assert changeset.errors[:user_id] != nil
    end

    test "invalid changeset when action_type is missing" do
      attrs = %{
        user_id: 1,
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      changeset = ActionLog.changeset(%ActionLog{}, attrs)
      refute changeset.valid?
      assert changeset.errors[:action_type] != nil
    end

    test "invalid changeset when action_type is not in the allowed list" do
      attrs = %{
        user_id: 1,
        action_type: "invalid_action",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      changeset = ActionLog.changeset(%ActionLog{}, attrs)
      refute changeset.valid?
      assert changeset.errors[:action_type] != nil
    end

    test "accepts all valid action types" do
      valid_types = [
        "question_answered",
        "question_dismissed",
        "command_completed",
        "command_dismissed",
        "context_updated",
        "website_added",
        "website_scanned",
        "settings_updated"
      ]

      base_attrs = %{
        user_id: 1,
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      }

      for action_type <- valid_types do
        changeset = ActionLog.changeset(%ActionLog{}, Map.put(base_attrs, :action_type, action_type))
        assert changeset.valid?, "Expected valid changeset for action_type: #{action_type}"
      end
    end

    test "auto-sets timestamp when not provided" do
      attrs = %{
        user_id: 1,
        action_type: "website_added"
      }

      changeset = ActionLog.changeset(%ActionLog{}, attrs)
      assert changeset.valid?
      refute is_nil(Ecto.Changeset.get_field(changeset, :timestamp))
    end

    test "accepts optional entity_type and entity_id fields" do
      entity_id = Ecto.UUID.generate()

      attrs = %{
        user_id: 1,
        action_type: "question_answered",
        entity_type: "user_question",
        entity_id: entity_id,
        metadata: %{"response_time" => 42}
      }

      changeset = ActionLog.changeset(%ActionLog{}, attrs)
      assert changeset.valid?
    end
  end

  # ---------------------------------------------------------------------------
  # ActionLog.log/1
  # ---------------------------------------------------------------------------

  describe "log/1" do
    test "inserts an action log record into the database" do
      user = user_fixture()

      attrs = %{
        user_id: user.id,
        action_type: "website_added",
        entity_type: "website",
        entity_id: Ecto.UUID.generate(),
        metadata: %{"source" => "test"}
      }

      assert {:ok, log} = ActionLog.log(attrs)
      assert log.id != nil
      assert log.user_id == user.id
      assert log.action_type == "website_added"
    end

    test "returns an error changeset for invalid attrs" do
      assert {:error, changeset} = ActionLog.log(%{action_type: "unknown_action"})
      refute changeset.valid?
    end
  end

  # ---------------------------------------------------------------------------
  # ActionLog.log_question_answered/4
  # ---------------------------------------------------------------------------

  describe "log_question_answered/4" do
    test "creates a log entry with correct action_type and metadata" do
      user = user_fixture()
      question_id = Ecto.UUID.generate()

      assert {:ok, log} =
               ActionLog.log_question_answered(user.id, question_id, "Yes, correct", 120)

      assert log.action_type == "question_answered"
      assert log.entity_type == "user_question"
      assert log.entity_id == question_id
      assert log.metadata["answer"] == "Yes, correct"
      assert log.metadata["response_time_seconds"] == 120
    end

    test "persists the record to the database" do
      user = user_fixture()
      question_id = Ecto.UUID.generate()

      assert {:ok, log} = ActionLog.log_question_answered(user.id, question_id, "No", 30)
      assert log.id != nil
    end
  end

  # ---------------------------------------------------------------------------
  # ActionLog.log_command_completed/3
  # ---------------------------------------------------------------------------

  describe "log_command_completed/3" do
    test "creates a log entry with correct action_type and metadata" do
      user = user_fixture()
      command_id = Ecto.UUID.generate()

      assert {:ok, log} = ActionLog.log_command_completed(user.id, command_id, 3600)

      assert log.action_type == "command_completed"
      assert log.entity_type == "command"
      assert log.entity_id == command_id
      assert log.metadata["time_to_complete"] == 3600
    end

    test "persists the record to the database" do
      user = user_fixture()
      command_id = Ecto.UUID.generate()

      assert {:ok, log} = ActionLog.log_command_completed(user.id, command_id, 0)
      assert log.id != nil
    end
  end
end
