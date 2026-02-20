# Website Analysis Directive (Step 1 of 2)

**Purpose:** Analyze websites and create structured context documents.
**This is STEP 1 only** - Do NOT generate commands. That happens in step 2.

Follow these steps sequentially.

## DATABASE ACCESS

Database connection string:
```bash
# PostgreSQL connection (adjust based on your config/dev.exs)
psql -d shepherd_dev
```

## STEP 1: FIND PENDING WEBSITES

Query the database for websites that need analysis:

```sql
SELECT id, url, name, user_id
FROM websites
WHERE status = 'pending_analysis'
ORDER BY inserted_at ASC
LIMIT 5;
```

For each website found, proceed with steps 2-5.

---

## STEP 2: UNDERSTAND THE WEBSITE

Use WebFetch to fetch the homepage:
```
WebFetch URL: <website_url>
Prompt: "Extract and summarize: 1) Main headline/value proposition, 2) Navigation menu items, 3) Primary CTA text and location, 4) Brief description of what this business offers"
```

Analyze the response to understand:
- What business is this?
- What do they offer?
- Who is the target audience?
- What type of business? (travel agency, tour operator, ecommerce, SaaS, etc.)

---

## STEP 3: IDENTIFY CONVERSION GOAL

Based on Step 2 analysis, determine:
- What is the PRIMARY action visitors should take?
  - Examples: "book tour", "request quote", "purchase product", "signup for trial", "contact sales", "download guide"
- Where is the main CTA on the homepage?
- What does the CTA say exactly?

---

## STEP 4: ANALYZE 8-STEP CONVERSION LADDER

For each step below, analyze the homepage (use WebFetch again if you need to check specific elements):

### Step 1 - Attention
- **Question:** Does the headline immediately grab attention and communicate value?
- **Check for:** Clear headline, strong value proposition visible immediately
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

### Step 2 - Engagement
- **Question:** Are there elements that encourage further exploration?
- **Check for:** Visual hierarchy, compelling subheadings, images, scannable layout
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

### Step 3 - Comprehension (OFTEN THE BIGGEST BOTTLENECK)
- **Question:** Can visitors understand EXACTLY what is being offered?
- **Check for:**
  - Detailed product/service descriptions
  - Pricing information or indication of cost
  - Specifications, features, what's included
  - Images or examples of products/services
  - Clear navigation to detail pages
- **Status:** good | weak | failing
- **Notes:** What works or what's missing
- **THIS IS CRITICAL:** Most websites fail here - visitors can't understand what they're buying

### Step 4 - Belief
- **Question:** Are there trust signals that build credibility?
- **Check for:** Testimonials, reviews, ratings, client logos, credentials, certifications, guarantees
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

### Step 5 - Desire
- **Question:** Are benefits clearly tied to visitor needs?
- **Check for:** Benefit-focused copy, outcome descriptions, problem-solution framing
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

### Step 6 - Urgency
- **Question:** Is there any reason to act now vs later?
- **Check for:** Limited availability, seasonal relevance, deadlines, scarcity (must be authentic)
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

### Step 7 - Intent
- **Question:** Is the CTA clear, visible, and action-oriented?
- **Check for:** Prominent CTA button, specific action language, easy to find
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

### Step 8 - Action
- **Question:** Is taking action easy and low-friction?
- **Check for:** Simple forms, multiple contact options (phone/email/chat), guest checkout
- **Status:** good | weak | failing
- **Notes:** What works or what's missing

---

## STEP 5: IDENTIFY THE BOTTLENECK

Review all 8 steps and identify:
- **Which step has the worst status?** (failing > weak > good)
- **Why does that step fail?** What is specifically missing or broken?
- **What needs to be added/fixed?**

Most websites fail at:
1. **Step 3 (Comprehension)** - visitors can't understand what's being offered
2. **Step 4 (Belief)** - no trust signals or social proof

Be honest and specific about the bottleneck.

---

## STEP 6: SAVE RESULTS TO DATABASE

Use Bash to execute psql commands and insert the analysis into the database.

### 6a. Build the JSON context document

Create a JSON document with this structure (use proper JSON escaping):

```json
{
  "concept": "One sentence - what this website does",
  "business_type": "travel_agency | tour_operator | ecommerce | saas | service | other",
  "target_destinations": ["if applicable - countries/regions"],
  "service_types": ["tours", "hotels", etc - or product categories"],
  "primary_cta": "Exact CTA text from homepage",
  "confusion": [{"issue": "anything unclear", "page": "where found"}],
  "scan_cache": {
    "pages_analyzed": ["homepage_url"],
    "scan_date": "2026-02-13T10:30:00Z",
    "homepage_summary": "Brief summary"
  },
  "conversion_goal": "the primary action visitors should take",
  "step_analysis": {
    "step_1_attention": {"status": "good", "notes": "..."},
    "step_2_engagement": {"status": "weak", "notes": "..."},
    "step_3_comprehension": {"status": "failing", "notes": "..."},
    "step_4_belief": {"status": "weak", "notes": "..."},
    "step_5_desire": {"status": "good", "notes": "..."},
    "step_6_urgency": {"status": "failing", "notes": "..."},
    "step_7_intent": {"status": "good", "notes": "..."},
    "step_8_action": {"status": "weak", "notes": "..."}
  },
  "bottleneck_step": "step_3_comprehension",
  "bottleneck_issue": "Clear description of why this step fails - what's missing or broken"
}
```

### 6b. Insert into website_contexts table

```sql
-- First check if context already exists
SELECT id FROM website_contexts WHERE website_id = '<website_id>';

-- If exists, UPDATE:
UPDATE website_contexts
SET context_document = '<json_document>'::jsonb,
    updated_at = NOW()
WHERE website_id = '<website_id>';

-- If doesn't exist, INSERT:
INSERT INTO website_contexts (website_id, context_document, inserted_at, updated_at)
VALUES ('<website_id>', '<json_document>'::jsonb, NOW(), NOW());
```

### 6c. Update website status

```sql
UPDATE websites
SET status = 'analyzed',
    last_scanned_at = NOW()
WHERE id = '<website_id>';
```

**IMPORTANT:** Status is set to 'analyzed', NOT 'active'.
Command generation happens in step 2 (separate script).

---

## ⚠️ STOP HERE - ANALYSIS COMPLETE

**Do NOT generate commands in this step.**

Command generation is handled separately by running:
```bash
./bin/generate_commands.sh
```

That script uses CLAUDE_COMMAND_GENERATION_DIRECTIVE.md to:
- Read your analysis from the database
- Apply the conversion ladder framework
- Generate specific, actionable commands

---

## EXAMPLE WORKFLOW

```bash
# 1. Find pending websites
psql -d shepherd_dev -c "SELECT id, url, name, user_id FROM websites WHERE status = 'pending_analysis' LIMIT 1;"

# Output: id=123, url=https://example.com, user_id=1

# 2. Analyze website
# Use WebFetch to fetch homepage and analyze

# 3. Build JSON and insert
psql -d shepherd_dev -c "
INSERT INTO website_contexts (website_id, context_document, inserted_at, updated_at)
VALUES ('123', '{\"concept\": \"...\", ...}'::jsonb, NOW(), NOW())
ON CONFLICT (website_id) DO UPDATE SET context_document = EXCLUDED.context_document;

UPDATE websites SET status = 'analyzed', last_scanned_at = NOW() WHERE id = '123';
"

# 4. STOP - Analysis complete
# To generate commands, run: ./bin/generate_commands.sh
```

---

## IMPORTANT NOTES

1. **Be specific in analysis** - generic observations aren't helpful
2. **Focus on conversion** - everything should relate to helping visitors convert
3. **Be honest about bottlenecks** - most sites fail at Step 3 (Comprehension)
4. **Escape JSON properly** - use proper escaping for SQL insertion
5. **Process one website at a time** - complete all steps before moving to next
6. **Stop after analysis** - Do NOT generate commands in this step

---

## SUCCESS CRITERIA

For each website processed:
- ✅ Context document saved to database with all required fields
- ✅ Website status updated to "analyzed" (NOT "active")
- ✅ last_scanned_at timestamp set
- ✅ Bottleneck clearly identified in context document
- ✅ Ready for step 2 (command generation)
