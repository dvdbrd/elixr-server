defmodule Shepherd.LLM.CommandManagerTest do
  use Shepherd.DataCase, async: true

  alias Shepherd.LLM.CommandManager

  import Shepherd.AccountsFixtures
  import Shepherd.WebsitesFixtures
  import Shepherd.CommandsFixtures

  # ---------------------------------------------------------------------------
  # get_pending_commands/3
  # ---------------------------------------------------------------------------

  describe "get_pending_commands/3" do
    test "returns pending commands sorted by urgency (critical first)" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      command_fixture(%{user_id: user.id, entity_id: entity_id, urgency: "low"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, urgency: "critical"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, urgency: "medium"})

      assert {:ok, commands} = CommandManager.get_pending_commands(user.id, "website", entity_id)
      urgencies = Enum.map(commands, & &1.urgency)
      assert urgencies == ["critical", "medium", "low"]
    end

    test "returns only pending commands, excludes completed ones" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "pending"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "completed"})

      assert {:ok, commands} = CommandManager.get_pending_commands(user.id, "website", entity_id)
      assert length(commands) == 1
      assert hd(commands).status == "pending"
    end

    test "returns empty list when no pending commands exist" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      assert {:ok, []} = CommandManager.get_pending_commands(user.id, "website", entity_id)
    end
  end

  # ---------------------------------------------------------------------------
  # get_all_commands/4
  # ---------------------------------------------------------------------------

  describe "get_all_commands/4" do
    test "returns commands of any status" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "pending"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "completed"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "dismissed"})

      assert {:ok, commands} = CommandManager.get_all_commands(user.id, "website", entity_id)
      assert length(commands) == 3
    end

    test "respects the limit parameter" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      for _ <- 1..5, do: command_fixture(%{user_id: user.id, entity_id: entity_id})

      assert {:ok, commands} = CommandManager.get_all_commands(user.id, "website", entity_id, 3)
      assert length(commands) == 3
    end

    test "returns empty list when user has no commands for entity" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      assert {:ok, []} = CommandManager.get_all_commands(user.id, "website", entity_id)
    end
  end

  # ---------------------------------------------------------------------------
  # create_command/1
  # ---------------------------------------------------------------------------

  describe "create_command/1" do
    test "creates a command with valid attributes" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      attrs = %{
        user_id: user.id,
        entity_type: "command",
        entity_id: entity_id,
        command_text: "Update the homepage value proposition to be clear and concise",
        urgency: "high",
        created_by: "llm"
      }

      assert {:ok, command} = CommandManager.create_command(attrs)
      assert command.user_id == user.id
      assert command.urgency == "high"
      assert command.status == "pending"
    end

    test "verifies website ownership when entity_type is website" do
      user1 = user_fixture()
      user2 = user_fixture()
      website = website_fixture(%{user_id: user1.id})

      attrs = %{
        user_id: user2.id,
        entity_type: "website",
        entity_id: website.id,
        command_text: "Improve conversion rate optimization on landing page",
        urgency: "medium"
      }

      assert {:error, :unauthorized} = CommandManager.create_command(attrs)
    end

    test "returns error when user_id is missing" do
      assert {:error, :user_id_required} =
               CommandManager.create_command(%{
                 entity_type: "website",
                 entity_id: Ecto.UUID.generate(),
                 command_text: "Some command text here"
               })
    end

    test "returns changeset error for invalid attrs (command_text too short)" do
      user = user_fixture()
      website = website_fixture(%{user_id: user.id})

      assert {:error, changeset} =
               CommandManager.create_command(%{
                 user_id: user.id,
                 entity_type: "website",
                 entity_id: website.id,
                 command_text: "short"
               })

      assert changeset.errors[:command_text] != nil
    end
  end

  # ---------------------------------------------------------------------------
  # complete_command/2
  # ---------------------------------------------------------------------------

  describe "complete_command/2" do
    test "marks a pending command as completed and sets completed_at" do
      user = user_fixture()
      command = command_fixture(%{user_id: user.id})

      assert {:ok, updated} = CommandManager.complete_command(user.id, command.id)
      assert updated.status == "completed"
      refute is_nil(updated.completed_at)
    end

    test "returns error when command does not exist or belongs to another user" do
      user = user_fixture()
      other_user = user_fixture()
      command = command_fixture(%{user_id: other_user.id})

      assert {:error, :not_found} = CommandManager.complete_command(user.id, command.id)
    end

    test "returns error when command is already completed" do
      user = user_fixture()
      command = command_fixture(%{user_id: user.id, status: "completed"})

      assert {:error, :not_found} = CommandManager.complete_command(user.id, command.id)
    end
  end

  # ---------------------------------------------------------------------------
  # dismiss_command/2
  # ---------------------------------------------------------------------------

  describe "dismiss_command/2" do
    test "marks a pending command as dismissed and sets dismissed_at" do
      user = user_fixture()
      command = command_fixture(%{user_id: user.id})

      assert {:ok, updated} = CommandManager.dismiss_command(user.id, command.id)
      assert updated.status == "dismissed"
      refute is_nil(updated.dismissed_at)
    end

    test "returns error when command does not belong to the user" do
      user = user_fixture()
      other_user = user_fixture()
      command = command_fixture(%{user_id: other_user.id})

      assert {:error, :not_found} = CommandManager.dismiss_command(user.id, command.id)
    end
  end

  # ---------------------------------------------------------------------------
  # get_command_stats/1
  # ---------------------------------------------------------------------------

  describe "get_command_stats/1" do
    test "returns correct counts by status" do
      user = user_fixture()
      entity_id = Ecto.UUID.generate()

      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "pending"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "pending"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "completed"})
      command_fixture(%{user_id: user.id, entity_id: entity_id, status: "dismissed"})

      stats = CommandManager.get_command_stats(user.id)

      assert stats.pending == 2
      assert stats.completed == 1
      assert stats.dismissed == 1
      assert stats.overdue == 0
    end

    test "returns zeroes for a user with no commands" do
      user = user_fixture()

      stats = CommandManager.get_command_stats(user.id)

      assert stats == %{pending: 0, completed: 0, dismissed: 0, overdue: 0}
    end
  end
end
