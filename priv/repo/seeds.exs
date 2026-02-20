alias Shepherd.Repo
alias Shepherd.Accounts.User
alias Shepherd.Websites.{Website, WebsiteContext, UserQuestion}
alias Shepherd.Commands.Command
alias Shepherd.LLM.{Feedback, WebsiteManager}

# Clean up
Repo.delete_all(Feedback)
Repo.delete_all(Command)
Repo.delete_all(UserQuestion)
Repo.delete_all(WebsiteContext)
Repo.delete_all(Website)

# User
user =
  case Repo.get_by(User, email: "test@example.com") do
    nil ->
      {:ok, user} =
        User.email_changeset(%User{}, %{
          email: "test@example.com",
          password: "password123"
        })
        |> Repo.insert()

      user

    user ->
      user
  end

# Website with auto-scan
{:ok, website} =
  WebsiteManager.create_website_with_scan(%{
    user_id: user.id,
    url: "https://gudauri.school",
    name: "Gudauri School"
  })

IO.puts("\n✓ Seeded: #{user.email} | #{website.name}")
IO.puts("✓ Website status: pending_analysis")
IO.puts("")
IO.puts("Two-step analysis process:")
IO.puts("  1. Run './bin/analyze_websites.sh' to analyze website")
IO.puts("  2. Run './bin/generate_commands.sh' to generate improvement commands")
IO.puts("")
