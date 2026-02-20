# Command Generation Directive (Step 2 of 2)

**Purpose:** Generate actionable improvement commands based on website analysis.
**Prerequisite:** Website must have status='analyzed' and existing context document.

Follow these steps sequentially.

---

## DATABASE ACCESS

Database connection string:
```bash
psql -d shepherd_dev
```

---

## STEP 1: FIND ANALYZED WEBSITES

Query the database for websites that have been analyzed but don't have commands yet:

```sql
SELECT w.id, w.url, w.name, w.user_id, wc.context_document
FROM websites w
JOIN website_contexts wc ON wc.website_id = w.id
WHERE w.status = 'analyzed'
ORDER BY w.last_scanned_at DESC
LIMIT 5;
```

For each website found, proceed with steps 2-4.

---

## STEP 2: REVIEW ANALYSIS

Read the context document from the query above. Pay special attention to:

1. **bottleneck_step** - Which step has the worst performance?
2. **bottleneck_issue** - What specifically is failing?
3. **step_analysis** - Detailed notes for each of the 8 steps
4. **conversion_goal** - What action should visitors take?
5. **business_type** - What kind of business is this?

---

## STEP 3: READ CONVERSION LADDER FRAMEWORK

Open and read: `CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md`

This file contains:
- Detailed explanation of the 8-step conversion ladder
- Common bottlenecks by industry
- Optimization strategies for each step
- Prioritization framework

Use this framework to understand:
- Why the bottleneck matters
- What typical fixes work for this type of bottleneck
- How to prioritize recommendations

---

## STEP 4: GENERATE COMMANDS

Based on the analysis + framework, generate 3-7 actionable commands.

### Command Generation Strategy:

**60-70% of commands should fix the bottleneck step**
- If bottleneck is Step 3 (Comprehension), most commands should add clarity
- If bottleneck is Step 4 (Belief), most commands should add trust signals
- Focus on the highest-impact fixes first

**Commands must be:**
- ✅ **Specific** - "Add pricing table to homepage with 3 package tiers" NOT "improve pricing"
- ✅ **Actionable** - User can implement without technical expertise
- ✅ **Impact-focused** - Explain the conversion impact in reasoning
- ✅ **Prioritized** - critical > high > medium > low

**Urgency Levels:**
- `critical` - Fixes the main bottleneck (1-2 commands)
- `high` - Fixes other failing steps or secondary bottlenecks (2-3 commands)
- `medium` - Fixes weak steps or enhancements (1-2 commands)
- `low` - Nice-to-have optimizations (0-1 commands)

### Example Commands by Bottleneck:

**Bottleneck: Step 3 (Comprehension) - Most Common**
```
Command: "Create 'Services' page with detailed descriptions of each lesson type, pricing, duration, and what's included"
Urgency: critical
Reasoning: "Step 3 (Comprehension) is failing at 30%. Visitors cannot understand what they're buying. This is costing 40-60% of potential conversions. Adding detailed service information will increase comprehension to 70%+."
```

**Bottleneck: Step 4 (Belief)**
```
Command: "Add testimonials section on homepage with 5-10 customer reviews including photos and star ratings"
Urgency: critical
Reasoning: "Step 4 (Belief) is failing at 35%. No social proof visible. Adding testimonials typically increases trust and conversion by 20-30%."
```

**Bottleneck: Step 6 (Urgency)**
```
Command: "Add 'Limited availability - only 5 spots left for January' messaging to booking section"
Urgency: critical
Reasoning: "Step 6 (Urgency) is failing at 25%. No reason to book now vs later. Authentic scarcity messaging can double booking rate for seasonal businesses."
```

---

## STEP 5: INSERT COMMANDS INTO DATABASE

For each command generated (3-7 total):

```sql
INSERT INTO commands (
  user_id,
  entity_type,
  entity_id,
  command_text,
  urgency,
  llm_reasoning,
  status,
  created_by,
  inserted_at,
  updated_at
)
VALUES (
  <user_id>,              -- From website record
  'website',              -- Entity type
  '<website_id>',         -- Website UUID
  'Specific command text here',
  'critical',             -- critical | high | medium | low
  'Detailed reasoning explaining conversion impact',
  'pending',              -- Always pending
  'llm',                  -- Always llm
  NOW(),
  NOW()
);
```

Repeat for each command.

---

## STEP 6: UPDATE WEBSITE STATUS

After all commands are inserted:

```sql
UPDATE websites
SET status = 'active'
WHERE id = '<website_id>';
```

**IMPORTANT:** Status changes from 'analyzed' to 'active'.

---

## EXAMPLE WORKFLOW

```bash
# 1. Find analyzed websites
psql -d shepherd_dev -c "
SELECT w.id, w.url, w.name, w.user_id, wc.context_document->>'bottleneck_step' as bottleneck
FROM websites w
JOIN website_contexts wc ON wc.website_id = w.id
WHERE w.status = 'analyzed'
LIMIT 1;
"

# Output: id=abc-123, url=https://example.com, bottleneck=step_3_comprehension

# 2. Review context document (already in query above)
# 3. Read CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md
# 4. Generate 3-7 commands based on bottleneck

# 5. Insert commands
psql -d shepherd_dev -c "
INSERT INTO commands (user_id, entity_type, entity_id, command_text, urgency, llm_reasoning, status, created_by, inserted_at, updated_at)
VALUES
  (1, 'website', 'abc-123', 'Create detailed services page...', 'critical', 'Step 3 failing...', 'pending', 'llm', NOW(), NOW()),
  (1, 'website', 'abc-123', 'Add testimonials section...', 'high', 'Build trust...', 'pending', 'llm', NOW(), NOW()),
  (1, 'website', 'abc-123', 'Add urgency messaging...', 'medium', 'Increase immediate bookings...', 'pending', 'llm', NOW(), NOW());
"

# 6. Update status
psql -d shepherd_dev -c "UPDATE websites SET status = 'active' WHERE id = 'abc-123';"
```

---

## COMMAND QUALITY CHECKLIST

Before inserting each command, verify:

- [ ] **Specific** - Describes exactly what to add/change/fix
- [ ] **Location specified** - Says where on the site (homepage, services page, etc.)
- [ ] **Addresses bottleneck** - Directly fixes identified conversion issue
- [ ] **Urgency justified** - Reasoning explains why this urgency level
- [ ] **Impact quantified** - Mentions estimated conversion improvement
- [ ] **Actionable** - User can implement without being a developer

---

## SUCCESS CRITERIA

For each website processed:
- ✅ Read existing context document from database
- ✅ Reviewed conversion ladder framework
- ✅ Generated 3-7 specific, actionable commands
- ✅ 60-70% of commands address the main bottleneck
- ✅ All commands inserted into database
- ✅ Website status updated to 'active'
- ✅ Commands sorted by urgency (critical first)

---

## IMPORTANT NOTES

1. **Focus on the bottleneck** - 60-70% of commands should fix the worst-performing step
2. **Be specific** - "Add pricing table with 3 tiers" NOT "improve pricing"
3. **Explain impact** - Always quantify or estimate conversion improvement
4. **Use framework** - Reference CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md for best practices
5. **One website at a time** - Complete all commands for one site before moving to next
6. **Quality over quantity** - 3 great commands > 7 mediocre ones
