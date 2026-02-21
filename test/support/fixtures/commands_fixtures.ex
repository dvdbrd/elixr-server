defmodule Shepherd.CommandsFixtures do
  @moduledoc """
  Test helpers for creating command entities.
  """

  alias Shepherd.Repo
  alias Shepherd.Commands.Command

  def valid_command_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      user_id: nil,
      entity_type: "website",
      entity_id: Ecto.UUID.generate(),
      command_text: "Update the homepage hero section to clearly state the value proposition in under 10 words",
      urgency: "medium",
      status: "pending",
      created_by: "llm",
      llm_reasoning: "The homepage lacks a clear value proposition, which is step 3 of the conversion ladder."
    })
  end

  def command_fixture(attrs \\ %{}) do
    attrs = valid_command_attributes(attrs)

    if is_nil(attrs.user_id) do
      raise "command_fixture requires :user_id"
    end

    %Command{}
    |> Command.changeset(Map.take(attrs, [
      :user_id, :entity_type, :entity_id, :command_text,
      :urgency, :status, :created_by, :llm_reasoning, :deadline
    ]))
    |> Repo.insert!()
  end
end
