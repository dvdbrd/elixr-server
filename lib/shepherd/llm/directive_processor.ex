defmodule Shepherd.LLM.DirectiveProcessor do
  @moduledoc """
  Stub for directive processing.
  Will invoke LLM-driven logic when questions are answered.
  """
  require Logger

  def process(directive, _params) do
    Logger.debug("DirectiveProcessor.process/2 stub: #{inspect(directive)}")
    {:ok, nil}
  end
end
