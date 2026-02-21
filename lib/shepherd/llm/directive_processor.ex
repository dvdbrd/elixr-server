defmodule Shepherd.LLM.DirectiveProcessor do
  @moduledoc """
  Processes LLM directives triggered by user actions.
  Currently handles question_followup — other directives are handled by the CLI scripts.
  """

  require Logger

  alias Shepherd.LLM.Directives
  alias Shepherd.LLM.WebsiteManager
  alias Shepherd.Repo
  alias Shepherd.Websites.UserQuestion

  @doc """
  Process a directive with the given params.
  Returns {:ok, result} or {:error, reason}.
  """
  def process(directive_name, params) when is_binary(directive_name) do
    case Directives.get(directive_name) do
      nil ->
        Logger.warning("Unknown directive: #{directive_name}")
        {:error, :unknown_directive}

      directive ->
        Logger.info("Processing directive: #{directive_name}")
        execute(directive_name, directive, params)
    end
  end

  def process(directive_name, params) do
    Logger.debug("DirectiveProcessor.process/2: #{inspect(directive_name)} with #{inspect(params)}")
    {:ok, nil}
  end

  defp execute("question_followup", _directive, %{question_id: question_id, user_id: user_id}) do
    with question when not is_nil(question) <- Repo.get(UserQuestion, question_id),
         :ok <- if(question.user_id == user_id, do: :ok, else: :unauthorized),
         website_id when not is_nil(website_id) <- question.website_id,
         {:ok, context} <- WebsiteManager.get_context(user_id, website_id) do
      # Merge the answer into the confusion section of the context
      updated_confusion =
        (context["confusion"] || [])
        |> Enum.map(fn item ->
          if item["issue"] && String.contains?(to_string(question.question_text), to_string(item["issue"])) do
            Map.put(item, "resolved", true)
            |> Map.put("resolution", to_string(question.answer))
          else
            item
          end
        end)

      updated_context = Map.put(context, "confusion", updated_confusion)

      case WebsiteManager.update_context(user_id, website_id, updated_context) do
        {:ok, _} ->
          Logger.info("Updated context for website #{website_id} after question #{question_id}")
          {:ok, updated_context}

        error ->
          error
      end
    else
      nil -> {:error, :not_found}
      :unauthorized -> {:error, :unauthorized}
      {:error, _} = error -> error
      _ -> {:error, :processing_failed}
    end
  end

  defp execute(_directive_name, _directive, _params) do
    # Other directives (website_analysis, command_generation, feedback_generation)
    # are handled by the CLI scripts, not by the web application
    {:ok, nil}
  end
end
