defmodule Shepherd.FeedbackFixtures do
  @moduledoc """
  Test helpers for creating feedback entities.
  """

  alias Shepherd.Repo
  alias Shepherd.LLM.Feedback

  def valid_feedback_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      user_id: nil,
      feedback_type: "daily_summary",
      severity: "info",
      tone: "neutral",
      title: "Daily Progress Summary for #{Date.utc_today()}",
      message: "You completed 3 commands today. Your website conversion rate improved by 2%.",
      context_data: %{},
      status: "active"
    })
  end

  def feedback_fixture(attrs \\ %{}) do
    attrs = valid_feedback_attributes(attrs)

    if is_nil(attrs.user_id) do
      raise "feedback_fixture requires :user_id"
    end

    %Feedback{}
    |> Feedback.changeset(Map.take(attrs, [
      :user_id, :feedback_type, :severity, :tone,
      :title, :message, :context_data, :status, :expires_at
    ]))
    |> Repo.insert!()
  end
end
