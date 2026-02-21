defmodule Shepherd.Workers.MetricsAggregationWorker do
  @moduledoc """
  Oban worker that recalculates user behavior metrics from action logs.
  Runs periodically via Oban.Plugins.Cron (no args = all users) or on-demand (with user_id).
  """

  use Oban.Worker, queue: :default, max_attempts: 3

  alias Shepherd.Analytics
  alias Shepherd.Repo
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    case Analytics.recalculate_metrics(user_id) do
      {:ok, _metric} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  def perform(%Oban.Job{args: _args}) do
    user_ids =
      from(u in "users", select: u.id)
      |> Repo.all()

    Enum.each(user_ids, fn user_id ->
      Analytics.recalculate_metrics(user_id)
    end)

    :ok
  end
end
