defmodule Shepherd.LLM.ContextManager do
  @moduledoc """
  Thin adapter bridging HQ views to CommandManager.
  Stub module — will be expanded with full context management logic.
  """
  alias Shepherd.LLM.CommandManager

  def mark_command_completed(user_id, command_id) do
    CommandManager.complete_command(user_id, command_id)
  end
end
