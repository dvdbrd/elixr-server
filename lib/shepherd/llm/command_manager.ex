defmodule Shepherd.LLM.CommandManager do
  @moduledoc """
  Context module for managing LLM-issued commands.
  All functions enforce user_id scoping for security.
  """

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.Commands.Command
  alias Shepherd.Analytics.ActionLog

  @doc """
  Get all pending commands for a user and entity.
  Returns commands sorted by urgency (critical > high > medium > low) and created date.
  """
  def get_pending_commands(user_id, entity_type, entity_id) do
    query =
      from c in Command,
        where:
          c.user_id == ^user_id and
            c.entity_type == ^entity_type and
            c.entity_id == ^entity_id and
            c.status == "pending",
        order_by: [
          asc:
            fragment(
              "CASE ? WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END",
              c.urgency
            ),
          asc: c.inserted_at
        ]

    {:ok, Repo.all(query)}
  end

  @doc """
  Get all pending commands for a user and entity type (any entity_id).
  """
  def get_pending_commands_by_type(user_id, entity_type) do
    query =
      from c in Command,
        where:
          c.user_id == ^user_id and
            c.entity_type == ^entity_type and
            c.status == "pending",
        order_by: [
          asc:
            fragment(
              "CASE ? WHEN 'critical' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 WHEN 'low' THEN 4 END",
              c.urgency
            ),
          asc: c.inserted_at
        ]

    {:ok, Repo.all(query)}
  end

  @doc """
  Get all commands for a user and entity (any status).
  """
  def get_all_commands(user_id, entity_type, entity_id, limit \\ 50) do
    query =
      from c in Command,
        where:
          c.user_id == ^user_id and
            c.entity_type == ^entity_type and
            c.entity_id == ^entity_id,
        order_by: [desc: c.inserted_at],
        limit: ^limit

    {:ok, Repo.all(query)}
  end

  @doc """
  Create a new command.
  Verifies that the entity (website) belongs to the user before creating.
  """
  def create_command(attrs) do
    user_id = attrs[:user_id] || attrs["user_id"]
    entity_type = attrs[:entity_type] || attrs["entity_type"]
    entity_id = attrs[:entity_id] || attrs["entity_id"]

    cond do
      is_nil(user_id) ->
        {:error, :user_id_required}

      entity_type == "website" and not is_nil(entity_id) ->
        query =
          from w in Shepherd.Websites.Website,
            where: w.id == ^entity_id and w.user_id == ^user_id

        case Repo.one(query) do
          nil -> {:error, :unauthorized}
          _website ->
            %Command{}
            |> Command.changeset(attrs)
            |> Repo.insert()
        end

      true ->
        %Command{}
        |> Command.changeset(attrs)
        |> Repo.insert()
    end
  end

  @doc """
  Mark a command as completed.
  Verifies user owns the command before updating.
  """
  def complete_command(user_id, command_id) do
    query =
      from c in Command,
        where: c.id == ^command_id and c.user_id == ^user_id and c.status == "pending"

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      command ->
        case command |> Command.complete_changeset() |> Repo.update() do
          {:ok, updated} ->
            ActionLog.log_command_completed(user_id, command_id, 0)
            {:ok, updated}

          error ->
            error
        end
    end
  end

  @doc """
  Dismiss a command.
  Verifies user owns the command before updating.
  """
  def dismiss_command(user_id, command_id) do
    query =
      from c in Command,
        where: c.id == ^command_id and c.user_id == ^user_id and c.status == "pending"

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      command ->
        case command |> Command.dismiss_changeset() |> Repo.update() do
          {:ok, updated} ->
            ActionLog.log(%{
              user_id: user_id,
              action_type: "command_dismissed",
              entity_type: "command",
              entity_id: command_id
            })
            {:ok, updated}

          error ->
            error
        end
    end
  end

  @doc """
  Get command statistics for a user.
  Returns counts by status.
  """
  def get_command_stats(user_id) do
    query =
      from c in Command,
        where: c.user_id == ^user_id,
        group_by: c.status,
        select: {c.status, count(c.id)}

    results = Repo.all(query) |> Map.new()

    %{
      pending: Map.get(results, "pending", 0),
      completed: Map.get(results, "completed", 0),
      dismissed: Map.get(results, "dismissed", 0),
      overdue: Map.get(results, "overdue", 0)
    }
  end
end
