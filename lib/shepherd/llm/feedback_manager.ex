defmodule Shepherd.LLM.FeedbackManager do
  @moduledoc """
  Context module for managing LLM-generated feedback.
  Provides functions to fetch, acknowledge, and dismiss feedback.
  """

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.LLM.Feedback

  @doc """
  Get all active feedback for a user.
  Returns feedback sorted by severity and creation time.
  """
  def get_active_feedback(user_id) do
    from(f in Feedback,
      where: f.user_id == ^user_id and f.status == "active",
      where: is_nil(f.expires_at) or f.expires_at > ^DateTime.utc_now(),
      order_by: [
        desc:
          fragment(
            "CASE ? WHEN 'critical' THEN 3 WHEN 'warning' THEN 2 WHEN 'success' THEN 1 ELSE 0 END",
            f.severity
          ),
        desc: f.inserted_at
      ]
    )
    |> Repo.all()
  end

  @doc """
  Get feedback by type for a user.
  """
  def get_feedback_by_type(user_id, feedback_type) do
    from(f in Feedback,
      where: f.user_id == ^user_id and f.feedback_type == ^feedback_type,
      where: f.status == "active",
      order_by: [desc: f.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Get all feedback (including acknowledged/dismissed) for a user.
  Useful for viewing history.
  """
  def get_all_feedback(user_id, limit \\ 50) do
    from(f in Feedback,
      where: f.user_id == ^user_id,
      order_by: [desc: f.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Get feedback statistics for a user.
  Returns counts by type and severity.
  """
  def get_feedback_stats(user_id) do
    active_count =
      from(f in Feedback,
        where: f.user_id == ^user_id and f.status == "active",
        select: count(f.id)
      )
      |> Repo.one()

    critical_count =
      from(f in Feedback,
        where: f.user_id == ^user_id and f.status == "active" and f.severity == "critical",
        select: count(f.id)
      )
      |> Repo.one()

    warning_count =
      from(f in Feedback,
        where: f.user_id == ^user_id and f.status == "active" and f.severity == "warning",
        select: count(f.id)
      )
      |> Repo.one()

    %{
      total_active: active_count,
      critical: critical_count,
      warning: warning_count
    }
  end

  @doc """
  Create new feedback for a user.
  """
  def create_feedback(attrs) do
    %Feedback{}
    |> Feedback.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Acknowledge feedback by ID.
  Verifies user owns the feedback.
  """
  def acknowledge_feedback(user_id, feedback_id) do
    case get_user_feedback(user_id, feedback_id) do
      nil ->
        {:error, :not_found}

      feedback ->
        feedback
        |> Feedback.acknowledge_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Dismiss feedback by ID.
  Verifies user owns the feedback.
  """
  def dismiss_feedback(user_id, feedback_id) do
    case get_user_feedback(user_id, feedback_id) do
      nil ->
        {:error, :not_found}

      feedback ->
        feedback
        |> Feedback.dismiss_changeset()
        |> Repo.update()
    end
  end

  @doc """
  Expire old feedback that has passed its expiration date.
  """
  def expire_old_feedback do
    now = DateTime.utc_now()

    from(f in Feedback,
      where: f.status == "active",
      where: not is_nil(f.expires_at),
      where: f.expires_at <= ^now
    )
    |> Repo.update_all(set: [status: "expired", updated_at: now |> DateTime.truncate(:second)])
  end

  @doc """
  Delete all feedback for a user (admin function).
  """
  def delete_all_user_feedback(user_id) do
    from(f in Feedback, where: f.user_id == ^user_id)
    |> Repo.delete_all()
  end

  # Private helper to get feedback with user verification
  defp get_user_feedback(user_id, feedback_id) do
    from(f in Feedback,
      where: f.id == ^feedback_id and f.user_id == ^user_id
    )
    |> Repo.one()
  end
end
