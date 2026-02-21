defmodule Shepherd.Websites.UserQuestion do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_questions" do
    field :user_id, :integer
    field :entity_type, :string
    field :entity_id, :binary_id
    field :website_id, :binary_id  # Kept for backward compatibility
    field :question_text, :string
    field :options, :map
    field :answer, :map
    field :question_type, :string, default: "onboarding"  # onboarding, complaint, clarification
    field :severity, :string, default: "info"  # info, warning, critical
    field :category, :string  # performance, ux, security, content, etc.
    field :generated_by, :string, default: "llm"  # llm, user, system
    field :answered_at, :utc_datetime
    field :status, :string, default: "pending"
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @valid_statuses ["pending", "answered", "dismissed", "expired"]
  @valid_severities ["info", "warning", "critical"]
  @valid_question_types ["onboarding", "complaint", "clarification", "feedback_request"]

  def changeset(question, attrs) do
    question
    |> cast(attrs, [
      :user_id, :entity_type, :entity_id, :website_id,
      :question_text, :options, :answer, :question_type,
      :severity, :category, :generated_by,
      :answered_at, :status, :expires_at
    ])
    |> validate_required([:user_id, :entity_type, :entity_id, :question_text, :options])
    |> validate_inclusion(:status, @valid_statuses)
    |> validate_inclusion(:severity, @valid_severities)
    |> validate_inclusion(:question_type, @valid_question_types)
    |> validate_length(:question_text, min: 10, max: 1000)
    |> validate_options_format()
  end

  def answer_changeset(question, %{answer: answer_value}) do
    question
    |> change(%{
      answer: %{"answer" => answer_value},
      answered_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: "answered"
    })
  end

  def answer_changeset(question, answer_value) when not is_map(answer_value) do
    question
    |> change(%{
      answer: %{"answer" => answer_value},
      answered_at: DateTime.utc_now() |> DateTime.truncate(:second),
      status: "answered"
    })
  end

  def dismiss_changeset(question, _attrs) do
    question
    |> change(%{status: "dismissed"})
  end

  defp validate_options_format(changeset) do
    case get_change(changeset, :options) do
      %{"choices" => choices} when is_list(choices) and length(choices) > 0 ->
        changeset

      _ ->
        add_error(changeset, :options, "must contain a 'choices' array with at least one option")
    end
  end

  # Helper to check if this is a complaint-type question
  def complaint?(question) do
    question.question_type == "complaint"
  end

  # Helper to check if this is an onboarding question
  def onboarding?(question) do
    question.question_type == "onboarding"
  end
end
