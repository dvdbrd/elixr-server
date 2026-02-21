defmodule Shepherd.Workers.ExpirationWorker do
  @moduledoc """
  Oban worker that expires stale questions and feedback.
  Runs hourly via Oban.Plugins.Cron.
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias Shepherd.LLM.{WebsiteManager, FeedbackManager}

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("ExpirationWorker: starting expiration sweep")

    {:ok, expired_questions} = WebsiteManager.expire_old_questions()
    {:ok, expired_feedback} = FeedbackManager.expire_old_feedback()

    Logger.info(
      "ExpirationWorker: expired #{expired_questions} questions, #{expired_feedback} feedback items"
    )

    :ok
  end
end
