defmodule Shepherd.LLM.Directives do
  @moduledoc """
  Registry of available LLM directives.
  Directives define what LLM analysis or command generation tasks can be triggered.
  """

  @directives %{
    "website_analysis" => %{
      name: "Website Analysis",
      description: "8-step conversion ladder analysis of a website",
      trigger: :on_website_added,
      requires: [:website_url],
      output: :context_document
    },
    "command_generation" => %{
      name: "Command Generation",
      description: "Generate prioritized action items from website analysis context",
      trigger: :on_analysis_complete,
      requires: [:context_document],
      output: :commands
    },
    "question_followup" => %{
      name: "Question Follow-up",
      description: "Re-analyze context after user answers a clarifying question",
      trigger: :on_question_answered,
      requires: [:question_id, :answer],
      output: :context_update
    },
    "feedback_generation" => %{
      name: "Feedback Generation",
      description: "Generate manager-style feedback based on user behavior metrics",
      trigger: :on_metrics_updated,
      requires: [:user_behavior_metric],
      output: :feedback
    }
  }

  @doc """
  Returns all available directives.
  """
  def all, do: @directives

  @doc """
  Get a specific directive by name.
  Returns nil if not found.
  """
  def get(name), do: Map.get(@directives, name)

  @doc """
  Get directives that match a given trigger.
  """
  def for_trigger(trigger) do
    @directives
    |> Enum.filter(fn {_name, directive} -> directive.trigger == trigger end)
    |> Map.new()
  end

  @doc """
  List all directive names.
  """
  def names, do: Map.keys(@directives)
end
