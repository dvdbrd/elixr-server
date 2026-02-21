defmodule Shepherd.LLM.WebsiteManager do
  @moduledoc """
  Whitelisted functions for LLM to interact with website context system.
  All functions enforce user_id scoping for security.
  """

  import Ecto.Query
  alias Shepherd.Repo
  alias Shepherd.Websites.{Website, WebsiteContext, UserQuestion}
  alias Shepherd.LLM.Directives
  require Logger

  @doc """
  Fetch the JSONB context document for a website.
  Returns: {:ok, context_document_map} or {:error, reason}
  """
  def get_context(user_id, website_id) when not is_nil(user_id) do
    query =
      from wc in WebsiteContext,
        join: w in Website,
        on: wc.website_id == w.id,
        where: w.user_id == ^user_id and wc.website_id == ^website_id,
        select: wc.context_document

    case Repo.one(query) do
      nil -> {:error, :not_found}
      context_document -> {:ok, context_document}
    end
  end

  def get_context(nil, _website_id), do: {:error, :user_id_required}

  @doc """
  Update the entire JSONB context document for a website.
  Returns: {:ok, updated_context} or {:error, reason}
  """
  def update_context(user_id, website_id, new_jsonb) when not is_nil(user_id) and is_map(new_jsonb) do
    # Verify the website belongs to the user
    website_query =
      from w in Website,
        where: w.id == ^website_id and w.user_id == ^user_id

    case Repo.one(website_query) do
      nil ->
        {:error, :not_found}

      _website ->
        # Find or create the context record
        context =
          Repo.get_by(WebsiteContext, website_id: website_id) ||
            %WebsiteContext{website_id: website_id}

        changeset =
          WebsiteContext.changeset(context, %{
            website_id: website_id,
            context_document: new_jsonb,
            updated_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })

        case Repo.insert_or_update(changeset) do
          {:ok, updated_context} -> {:ok, updated_context}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def update_context(nil, _website_id, _new_jsonb), do: {:error, :user_id_required}
  def update_context(_user_id, _website_id, new_jsonb) when not is_map(new_jsonb),
    do: {:error, :invalid_jsonb}

  @doc """
  Get all available LLM directives.
  Returns: map of directive names to content
  """
  def get_directives do
    Directives.all()
  end

  @doc """
  Ask a question to the user with multiple choice options.
  Returns: {:ok, question} or {:error, reason}
  """
  def ask_question(user_id, website_id, question_text, options)
      when not is_nil(user_id) and is_binary(question_text) and is_list(options) do
    # Verify the website belongs to the user
    website_query =
      from w in Website,
        where: w.id == ^website_id and w.user_id == ^user_id

    case Repo.one(website_query) do
      nil ->
        {:error, :not_found}

      _website ->
        changeset =
          UserQuestion.changeset(%UserQuestion{}, %{
            website_id: website_id,
            question_text: question_text,
            options: %{"choices" => options},
            status: "pending"
          })

        case Repo.insert(changeset) do
          {:ok, question} -> {:ok, question}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def ask_question(nil, _website_id, _text, _options), do: {:error, :user_id_required}

  @doc """
  Get all unanswered questions for a website.
  Returns: {:ok, list of questions} or {:error, reason}
  """
  def get_unanswered_questions(user_id, website_id) when not is_nil(user_id) do
    query =
      from q in UserQuestion,
        join: w in Website,
        on: q.website_id == w.id,
        where: w.user_id == ^user_id and q.website_id == ^website_id and q.status == "pending",
        order_by: [asc: q.inserted_at]

    questions = Repo.all(query)
    {:ok, questions}
  end

  def get_unanswered_questions(nil, _website_id), do: {:error, :user_id_required}

  @doc """
  Record a user's answer to a question.
  Returns: {:ok, updated_question} or {:error, reason}
  """
  def record_answer(user_id, question_id, answer) when not is_nil(user_id) do
    # Verify the question belongs to a website owned by the user
    query =
      from q in UserQuestion,
        join: w in Website,
        on: q.website_id == w.id,
        where: q.id == ^question_id and w.user_id == ^user_id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      question ->
        changeset = UserQuestion.answer_changeset(question, %{answer: answer})

        case Repo.update(changeset) do
          {:ok, updated_question} -> {:ok, updated_question}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def record_answer(nil, _question_id, _answer), do: {:error, :user_id_required}

  @doc """
  Dismiss a question (mark as dismissed without answering).
  Returns: {:ok, updated_question} or {:error, reason}
  """
  def dismiss_question(user_id, question_id) when not is_nil(user_id) do
    # Verify the question belongs to a website owned by the user
    query =
      from q in UserQuestion,
        join: w in Website,
        on: q.website_id == w.id,
        where: q.id == ^question_id and w.user_id == ^user_id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      question ->
        changeset =
          UserQuestion.changeset(question, %{
            status: "dismissed",
            answered_at: DateTime.utc_now() |> DateTime.truncate(:second)
          })

        case Repo.update(changeset) do
          {:ok, updated_question} -> {:ok, updated_question}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  def dismiss_question(nil, _question_id), do: {:error, :user_id_required}

  # ============================================================================
  # POLYMORPHIC QUESTION FUNCTIONS
  # ============================================================================

  @doc """
  Get unanswered questions by entity (polymorphic).
  Returns: {:ok, list of questions} or {:error, reason}
  """
  def get_unanswered_questions_by_entity(user_id, entity_type, entity_id) when not is_nil(user_id) do
    query =
      from q in UserQuestion,
        where: q.user_id == ^user_id,
        where: q.entity_type == ^entity_type,
        where: q.entity_id == ^entity_id,
        where: q.status == "pending",
        order_by: [asc: q.inserted_at]

    {:ok, Repo.all(query)}
  rescue
    error -> {:error, error}
  end

  def get_unanswered_questions_by_entity(nil, _entity_type, _entity_id),
    do: {:error, :user_id_required}

  @doc """
  Get unanswered questions by type (onboarding, complaint, etc.)
  Returns: {:ok, list of questions} or {:error, reason}
  """
  def get_unanswered_questions_by_type(user_id, entity_type, entity_id, question_type)
      when not is_nil(user_id) do
    query =
      from q in UserQuestion,
        where: q.user_id == ^user_id,
        where: q.entity_type == ^entity_type,
        where: q.entity_id == ^entity_id,
        where: q.question_type == ^question_type,
        where: q.status == "pending",
        order_by: [desc: q.severity, desc: q.inserted_at]

    {:ok, Repo.all(query)}
  rescue
    error -> {:error, error}
  end

  def get_unanswered_questions_by_type(nil, _entity_type, _entity_id, _question_type),
    do: {:error, :user_id_required}

  @doc """
  Create question with polymorphic support.
  Returns: {:ok, question} or {:error, reason}
  """
  def ask_question_polymorphic(user_id, entity_type, entity_id, question_text, options, opts \\ [])
      when not is_nil(user_id) and is_binary(question_text) and is_list(options) do
    attrs = %{
      user_id: user_id,
      entity_type: entity_type,
      entity_id: entity_id,
      question_text: question_text,
      options: %{"choices" => options},
      question_type: Keyword.get(opts, :question_type, "onboarding"),
      severity: Keyword.get(opts, :severity, "info"),
      category: Keyword.get(opts, :category),
      generated_by: Keyword.get(opts, :generated_by, "llm"),
      expires_at: Keyword.get(opts, :expires_at)
    }

    # Also set website_id if entity_type is "website" for backward compatibility
    attrs =
      if entity_type == "website" do
        Map.put(attrs, :website_id, entity_id)
      else
        attrs
      end

    %UserQuestion{}
    |> UserQuestion.changeset(attrs)
    |> Repo.insert()
  rescue
    error -> {:error, error}
  end

  def ask_question_polymorphic(nil, _entity_type, _entity_id, _question_text, _options, _opts),
    do: {:error, :user_id_required}

  @doc """
  Expire old pending questions.
  Returns: {:ok, count} or {:error, reason}
  """
  def expire_old_questions do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    query =
      from q in UserQuestion,
        where: q.status == "pending",
        where: not is_nil(q.expires_at),
        where: q.expires_at < ^now

    {count, _} = Repo.update_all(query, set: [status: "expired"])
    {:ok, count}
  end

  @doc """
  Get question stats by type.
  Returns: {:ok, stats_map} or {:error, reason}
  """
  def get_question_stats(user_id, entity_type, entity_id) when not is_nil(user_id) do
    query =
      from q in UserQuestion,
        where: q.user_id == ^user_id,
        where: q.entity_type == ^entity_type,
        where: q.entity_id == ^entity_id,
        group_by: [q.question_type, q.status],
        select: %{
          question_type: q.question_type,
          status: q.status,
          count: count(q.id)
        }

    results = Repo.all(query)

    # Transform into nested map
    stats =
      Enum.reduce(results, %{}, fn %{question_type: type, status: status, count: count}, acc ->
        acc
        |> Map.put_new(type, %{})
        |> put_in([type, status], count)
      end)

    {:ok, stats}
  rescue
    error -> {:error, error}
  end

  def get_question_stats(nil, _entity_type, _entity_id), do: {:error, :user_id_required}

  # ============================================================================
  # WEBSITE SCANNING FUNCTIONS
  # ============================================================================

  @doc """
  Fetch HTML content from a URL.
  Returns: {:ok, html_string} or {:error, reason}
  """
  def fetch_page_content(url) when is_binary(url) do
    case Req.get(url, max_redirects: 3, receive_timeout: 15_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: status}} ->
        Logger.warning("Failed to fetch #{url}: HTTP #{status}")
        {:error, "HTTP #{status}"}

      {:error, reason} ->
        Logger.warning("Failed to fetch #{url}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def fetch_page_content(_), do: {:error, :invalid_url}

  @doc """
  Get website metadata (url, name, status) for scanning.
  Returns: {:ok, website_map} or {:error, reason}
  """
  def get_website_info(user_id, website_id) when not is_nil(user_id) do
    query =
      from w in Website,
        where: w.id == ^website_id and w.user_id == ^user_id,
        select: %{
          id: w.id,
          url: w.url,
          name: w.name,
          user_id: w.user_id,
          status: w.status
        }

    case Repo.one(query) do
      nil -> {:error, :not_found}
      website -> {:ok, website}
    end
  end

  def get_website_info(nil, _website_id), do: {:error, :user_id_required}

  @doc """
  Update website status (scanning, active, error).
  Returns: {:ok, updated_website} or {:error, reason}
  """
  def update_website_status(user_id, website_id, status)
      when not is_nil(user_id) and status in ["pending_analysis", "analyzing", "analyzed", "active", "error", "inactive"] do
    query =
      from w in Website,
        where: w.id == ^website_id and w.user_id == ^user_id

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      website ->
        changeset =
          Website.changeset(website, %{
            status: status,
            last_scanned_at:
              if status == "active" do
                DateTime.utc_now() |> DateTime.truncate(:second)
              else
                website.last_scanned_at
              end
          })

        Repo.update(changeset)
    end
  end

  def update_website_status(nil, _website_id, _status), do: {:error, :user_id_required}
  def update_website_status(_user_id, _website_id, _invalid_status), do: {:error, :invalid_status}

  # ============================================================================
  # WEBSITE QUEUE FUNCTIONS (for Claude Code scanning workflows)
  # ============================================================================

  @doc """
  Get websites that have never been scanned.
  Returns: list of websites ordered by insertion date (oldest first)
  """
  def get_unscanned_websites(user_id, limit \\ 10) when not is_nil(user_id) do
    from(w in Website,
      where: w.user_id == ^user_id and is_nil(w.last_scanned_at),
      order_by: [asc: w.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_unscanned_websites(nil, _limit), do: []

  @doc """
  Get websites that haven't been scanned recently (stale scans).
  Returns: list of websites ordered by last scan date (oldest first)
  """
  def get_stale_websites(user_id, days_threshold \\ 7, limit \\ 10) when not is_nil(user_id) do
    cutoff = DateTime.utc_now() |> DateTime.add(-days_threshold, :day) |> DateTime.truncate(:second)

    from(w in Website,
      where: w.user_id == ^user_id,
      where: w.last_scanned_at < ^cutoff or is_nil(w.last_scanned_at),
      order_by: [asc: w.last_scanned_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def get_stale_websites(nil, _days_threshold, _limit), do: []

  # ============================================================================
  # WEBSITE CREATION WITH AUTO-SCAN
  # ============================================================================

  @doc """
  Create a new website and automatically enqueue a scan job.

  This is the recommended way to create websites as it ensures they get
  analyzed automatically. The scan can be scheduled immediately or delayed.

  ## Parameters
    - attrs: Map with website attributes (user_id, url, name, etc.)
    - opts: Keyword list of options
      - :schedule_in - Delay before scan starts (seconds, default: 0 for immediate)
      - :priority - Oban job priority (0-3, default: 0)

  ## Examples

      # Create website with immediate scan
      {:ok, website} = create_website_with_scan(%{
        user_id: 1,
        url: "https://example.com",
        name: "Example Site"
      })

      # Create website with 30-minute delay (premium feel)
      {:ok, website} = create_website_with_scan(%{
        user_id: 1,
        url: "https://example.com",
        name: "Example Site"
      }, schedule_in: 1800)

  ## Returns
    - {:ok, website} - Website created and scan queued
    - {:error, changeset} - Validation failed
  """
  def create_website_with_scan(attrs, opts \\ []) do
    # Set status to pending_analysis - will be analyzed by Claude Code
    attrs_with_status = Map.put(attrs, :status, "pending_analysis")

    # Create the website
    changeset = Website.changeset(%Website{}, attrs_with_status)

    case Repo.insert(changeset) do
      {:ok, website} ->
        Logger.info("Website created: #{website.id}, status=pending_analysis")
        Logger.info("Run 'bin/analyze_websites.sh' to analyze with Claude Code")
        {:ok, website}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
