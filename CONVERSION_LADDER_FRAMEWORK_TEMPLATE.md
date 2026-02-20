# Conversion Ladder Framework Template
## Universal Website/Product Conversion Optimization Framework

**Purpose:** This framework analyzes any website or product by mapping user psychology through an 8-step conversion journey, identifying drop-off points, and prioritizing fixes for maximum conversion improvement.

**How to use:** Copy this file into any project folder and ask Claude Code to:
> "Analyze this project using the CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md. Create a complete conversion analysis specific to this project."

---

## Part 1: Understanding the 8-Step Psychological Conversion Ladder

Every user must progress through these micro-commitments to convert:

```
1. ATTENTION      → "Yes, I pay attention"
2. ENGAGEMENT     → "Yes, I engage further"
3. COMPREHENSION  → "Yes, I understand"
4. BELIEF         → "Yes, I believe"
5. DESIRE         → "Yes, I want this"
6. URGENCY        → "Yes, I want this now"
7. INTENT         → "Yes, I will take action"
8. ACTION         → "Yes, I will take action now"
```

At each step, users can:
- ✅ **Progress** to the next step
- ❌ **Drop off** (leave the site/abandon)
- 🔄 **Get stuck** (confused, need intervention)

**Critical principle:** Conversion rate = multiplication of all step success rates

Example: 0.80 × 0.70 × 0.50 × 0.60 × 0.70 × 0.65 × 0.75 × 0.85 = 6.6% final conversion

**This means:** Improving a 50% bottleneck to 70% can double overall conversion!

---

## Part 2: Analysis Framework - What Claude Code Should Do

### Step 1: Identify Final Outcomes (Conversions)

**Task:** List all possible final outcomes a user can have.

**Primary conversions (desired):**
- [ ] Purchase/checkout completed
- [ ] Lead form submitted
- [ ] Contact via email
- [ ] Contact via phone/WhatsApp
- [ ] Demo request submitted
- [ ] Trial signup completed
- [ ] Account created
- [ ] Subscription purchased
- [ ] Other: _______________

**Secondary outcomes (partial success):**
- [ ] Email list signup
- [ ] Content download (gated)
- [ ] Wishlist/save for later
- [ ] Abandoned cart (but capturable)
- [ ] Other: _______________

**Non-conversions (understand why):**
- [ ] Clear rejection: "Not for me" (saw offer, consciously rejected)
- [ ] Confused: "I don't understand" (unclear value prop, poor navigation)
- [ ] Long-term interest: "Maybe later" (interested but not now)
- [ ] Unclear value: "So what?" (didn't see benefit)
- [ ] Comparison shopping: Left to evaluate competitors
- [ ] Other: _______________

---

### Step 2: Identify User Segments (By Psychology, Not Just Demographics)

**Task:** Define 4-8 user segments based on their mental state, intent level, and entry behavior.

**Template for each segment:**

```
### Segment [Name]
**Profile:** [Role/persona description]
**Mental state:** [What they're thinking when they arrive]
**Entry point:** [How they land on site - which page, from where]
**Intent level:** [Low/Medium/High/Very High]
**Timeline:** [How soon they need solution]
**Key need:** [What will make them convert]
**Main objection:** [What prevents conversion]
```

**Common segment types to look for:**
- Solution-aware (knows they need your product category)
- Problem-aware (has problem, exploring solutions)
- Constraint-led (has specific requirements: budget, time, features)
- Product-curious (heard about you, researching)
- Comparison shopping (evaluating you vs competitors)
- Impulse/emotional (ready to buy now if appealing)
- Skeptical/cautious (needs lots of proof before trusting)

**Instructions for Claude:**
- Analyze the website structure, navigation, and entry points
- Infer user segments from how the site is organized
- Consider different intent levels and entry behaviors
- Define 4-8 distinct segments

---

### Step 3: Identify Offers/Products/Paths

**Task:** List all distinct offers, products, or conversion paths available.

**Examples:**
- E-commerce: Product categories, featured products, sale items
- SaaS: Different pricing tiers, free trial, enterprise contact
- Service business: Service types, packages, custom quotes
- Content site: Premium subscriptions, course purchases, memberships

**For each offer, document:**
- [ ] What it is
- [ ] Entry points (how users find it)
- [ ] Target segment(s)
- [ ] Current conversion path (page sequence)
- [ ] Key differentiators

**Instructions for Claude:**
- Identify all distinct conversion paths
- Map navigation structure (navbar, homepage sections, CTAs)
- Note which user segments each offer targets
- Document current page flows

---

### Step 4: Map Each Offer Through the 8-Step Ladder

**This is the core analysis.** For each offer/path, analyze each of the 8 steps:

---

#### **STEP 1: ATTENTION → "Yes, I pay attention"**

**Questions to answer:**
- How does the user arrive at this entry point?
- What captures their attention initially?
- Does the headline/hero match their expectation?
- Is the value proposition immediately clear?

**Drop-off risks to identify:**
- Generic or unclear headline
- Slow page load
- Visual clutter
- Mismatch between ad/link and landing page
- Mobile experience issues

**Success indicators:**
- Clear, compelling headline
- Strong visual hierarchy
- Fast load time
- Immediate relevance

**Estimate:** What % of visitors who land here actually pay attention? (vs immediate bounce)

**Optimization opportunities:**
- Headline improvements
- Visual design updates
- Page speed optimization
- Above-the-fold clarity

---

#### **STEP 2: ENGAGEMENT → "Yes, I engage further"**

**Questions to answer:**
- What makes users scroll, click, or explore more?
- Is there a clear path to follow?
- Are there engagement hooks (images, videos, interactive elements)?
- Do subheadings draw users deeper?

**Drop-off risks to identify:**
- Wall of text
- No visual breaks
- Unclear what to do next
- Boring or irrelevant content
- No progressive disclosure

**Success indicators:**
- Clear content structure
- Visual variety
- Compelling subheadings
- Interactive elements
- Clear next steps

**Estimate:** Of those who paid attention, what % engage further? (scroll, click, read more)

**Optimization opportunities:**
- Content structure improvements
- Visual engagement elements
- Progressive disclosure design
- Storytelling approach

---

#### **STEP 3: COMPREHENSION → "Yes, I understand"**

**Questions to answer:**
- Does the user understand what you're offering?
- Can they see exactly what they'll get?
- Are features/benefits clearly explained?
- Is the product/service scope clear?
- Are there visual aids (images, videos, diagrams)?

**Drop-off risks to identify (THIS IS OFTEN THE BIGGEST BOTTLENECK):**
- Vague descriptions
- Jargon or technical language
- No product images/demos
- Unclear pricing or packages
- Missing key information (what's included, what's not)
- Disconnected navigation (can't find details)

**Success indicators:**
- Clear, specific descriptions
- Visual product/service representation
- Detailed specifications
- Examples or use cases
- FAQ or detailed info accessible

**Estimate:** Of those engaged, what % actually understand what you offer?

**This is typically the lowest % and biggest opportunity for improvement.**

**Optimization opportunities (CRITICAL):**
- Add detailed product/service descriptions
- Include images, videos, demos
- Create product/service detail pages
- Link all mentions to detail pages
- Add specifications, inclusions/exclusions
- Provide examples and use cases
- Simplify language

---

#### **STEP 4: BELIEF → "Yes, I believe"**

**Questions to answer:**
- Does the user trust you can deliver?
- Are there proof points (testimonials, reviews, case studies)?
- Do credentials and certifications appear?
- Is there social proof (customer count, ratings)?
- Are there trust signals (guarantees, security badges)?

**Drop-off risks to identify:**
- No testimonials or reviews
- No social proof
- Generic claims without evidence
- No credentials or certifications
- Lack of transparency
- No risk reversal (guarantees)

**Success indicators:**
- Customer testimonials
- Reviews/ratings
- Case studies with outcomes
- Client logos
- Trust badges
- Credentials/certifications
- Money-back guarantee
- Clear refund policy

**Estimate:** Of those who understand, what % believe you can deliver?

**Optimization opportunities:**
- Add testimonials throughout
- Display reviews prominently
- Create case studies
- Show social proof metrics
- Add trust badges
- Highlight credentials
- Offer guarantees

---

#### **STEP 5: DESIRE → "Yes, I want this"**

**Questions to answer:**
- Does the user want the outcome you provide?
- Have you connected benefits to their specific pain points?
- Is there emotional appeal?
- Can they visualize themselves using it?
- Have you overcome objections?

**Drop-off risks to identify:**
- Generic benefits not personalized
- No emotional connection
- Benefits not compelling enough
- Unclear outcome/transformation
- Objections not addressed
- No differentiation from competitors

**Success indicators:**
- Benefits clearly tied to user problems
- Emotional triggers present
- Outcome/transformation visualized
- Objections proactively addressed
- Unique value proposition clear
- Compelling reason to choose you

**Estimate:** Of those who believe, what % actually desire this outcome?

**Optimization opportunities:**
- Tie features to specific pain points
- Use outcome-focused language
- Add emotional storytelling
- Address common objections
- Highlight differentiation
- Show transformation (before/after)

---

#### **STEP 6: URGENCY → "Yes, I want this now"**

**Questions to answer:**
- Why should the user act now vs later?
- Are there urgency triggers (scarcity, deadlines)?
- Is there FOMO (fear of missing out)?
- Are there time-sensitive incentives?

**Drop-off risks to identify:**
- No urgency messaging
- No reason to act now
- "I'll come back later" mentality
- No consequences for delay
- Fake/manipulative urgency (damages trust)

**Success indicators:**
- Authentic scarcity (limited spots, inventory)
- Time-sensitive offers (deadline mentioned)
- Seasonal/timing relevance
- "Available now" vs waiting
- Early bird/first-mover benefits

**Estimate:** Of those who desire it, what % want it now vs later?

**Optimization opportunities:**
- Add availability indicators
- Show booking/purchase timelines
- Highlight seasonal relevance
- Offer time-limited incentives
- Show what they lose by waiting
- **CRITICAL: Must be authentic, not manipulative**

---

#### **STEP 7: INTENT → "Yes, I will take action"**

**Questions to answer:**
- Has the user decided to take action?
- Is the next step clear?
- Is the CTA visible and compelling?
- Do they know what happens after clicking?
- Are there multiple paths to convert (phone, form, chat)?

**Drop-off risks to identify:**
- CTA not visible or clear
- Generic CTA text ("Submit", "Click here")
- Unclear what happens next
- No alternative contact methods
- CTA appears too early (before comprehension/belief)
- CTA too late or hard to find

**Success indicators:**
- Clear, action-oriented CTA
- CTA placement after information provided
- Multiple conversion options (form, phone, chat)
- "What happens next" explanation
- Low-friction next step
- Reduced commitment language ("Free consultation", "No obligation")

**Estimate:** Of those with urgency, what % form intent to act?

**Optimization opportunities:**
- Make CTAs specific and contextual
- Place CTAs after comprehension is achieved
- Add "What happens next" messaging
- Offer multiple contact methods
- Reduce perceived commitment
- Add reassurance ("Free", "No obligation")

---

#### **STEP 8: ACTION → "Yes, I will take action now"**

**Questions to answer:**
- Is it easy to complete the action?
- Is the form/checkout simple?
- Are there unnecessary friction points?
- Is there immediate confirmation?
- Is the action mobile-friendly?

**Drop-off risks to identify:**
- Long or complex forms
- Too many required fields
- Payment friction
- Technical errors
- No immediate feedback
- Mobile usability issues
- No alternative action methods

**Success indicators:**
- Short, simple forms (only essential fields)
- Multiple payment options
- Guest checkout available
- Mobile-optimized
- Immediate confirmation
- Progress indicators for multi-step
- Alternative methods (WhatsApp, phone)

**Estimate:** Of those with intent, what % complete the action?

**Optimization opportunities:**
- Reduce form fields
- Add autofill/autocomplete
- Enable one-click options (WhatsApp, phone)
- Provide progress indicators
- Add instant confirmation
- Optimize for mobile
- Offer alternative action paths
- Remove unnecessary steps

---

### Step 5: Calculate Conversion Rates for Each Offer

**Task:** For each offer/path, multiply the estimated success rates across all 8 steps.

**Example calculation:**
```
Offer: [Name]
Step 1 (Attention):     80% pass
Step 2 (Engagement):    70% pass
Step 3 (Comprehension): 50% pass  ← BOTTLENECK
Step 4 (Belief):        60% pass
Step 5 (Desire):        70% pass
Step 6 (Urgency):       65% pass
Step 7 (Intent):        75% pass
Step 8 (Action):        85% pass

Overall conversion: 0.80 × 0.70 × 0.50 × 0.60 × 0.70 × 0.65 × 0.75 × 0.85 = 6.6%
```

**Create a summary table:**

| Offer/Path | Current Conversion | Critical Bottleneck | Fix Priority |
|------------|-------------------|---------------------|--------------|
| [Offer 1]  | X.X%              | Step X: Description | Critical     |
| [Offer 2]  | X.X%              | Step X: Description | High         |
| [Offer 3]  | X.X%              | Step X: Description | Medium       |

---

### Step 6: Identify Universal Patterns

**Task:** Look for patterns across all offers:

**Common bottlenecks:**
- Which step has the lowest success rate across most offers?
- Are there consistent issues (e.g., always low belief, always poor comprehension)?
- Which offers perform best/worst and why?

**Universal insights:**
- What works well universally (to replicate)?
- What fails universally (to fix first)?
- Are there structural issues affecting all paths?

**Segment-specific issues:**
- Do certain user segments have unique bottlenecks?
- Are some segments better served than others?
- Where should you focus based on segment value?

---

### Step 7: Create Implementation Roadmap

**Task:** Prioritize fixes based on:
1. **Impact:** How much conversion improvement expected?
2. **Effort:** How difficult/time-consuming to implement?
3. **Universality:** Does it improve multiple offers or just one?

**Framework for prioritization:**

```
PHASE 1: Critical Fixes (Est. +XXX% conversion gain)
- Fix the biggest bottleneck across all/most offers
- Usually Step 3 (Comprehension) or Step 4 (Belief)
- High impact, medium-high effort
- Implement these first

PHASE 2: High-Value Improvements (Est. +XX% conversion gain)
- Secondary bottlenecks
- Universal improvements (testimonials, social proof)
- Medium impact, medium effort
- Implement after Phase 1

PHASE 3: Friction Reduction (Est. +XX% conversion gain)
- Simplify actions (Step 8)
- Improve CTAs (Step 7)
- Add urgency (Step 6)
- Low-medium impact, low-medium effort
- Quick wins

PHASE 4: Optimization & Testing (Est. +XX% conversion gain)
- A/B testing opportunities
- Content improvements
- Design refinements
- Low-medium impact, low effort
- Continuous improvement
```

**For each fix, document:**
- **What to change:** Specific, actionable description
- **Where to change it:** Which pages/components
- **Impact estimate:** Expected conversion improvement
- **Effort estimate:** Low/Medium/High
- **Priority:** Critical/High/Medium/Low

---

### Step 8: Project Expected Improvements

**Task:** Calculate expected conversion rates after fixes:

| Offer/Path | Current | After Phase 1 | After Phase 2 | After All Phases |
|------------|---------|---------------|---------------|------------------|
| [Offer 1]  | X.X%    | X.X%          | X.X%          | X.X%             |
| [Offer 2]  | X.X%    | X.X%          | X.X%          | X.X%             |
| Overall    | X.X%    | X.X%          | X.X%          | X.X%             |

**Example calculation for improvement:**
```
Current: Step 3 comprehension at 50%
After fix: Step 3 comprehension at 75%

Before: 0.80 × 0.70 × 0.50 × 0.60 × 0.70 × 0.65 × 0.75 × 0.85 = 6.6%
After:  0.80 × 0.70 × 0.75 × 0.60 × 0.70 × 0.65 × 0.75 × 0.85 = 9.9%

Improvement: +50% conversion rate (from 6.6% to 9.9%)
```

---

## Part 3: Output Format (What Claude Should Produce)

Claude Code should create a comprehensive markdown document with:

### 1. Executive Summary
- Current overall conversion rate (estimated)
- Critical bottlenecks identified
- Expected improvement after fixes
- Top 3 priorities

### 2. User Segments (4-8 segments)
- Profile, mental state, entry point, intent, needs for each

### 3. Offers/Paths Identified
- List of distinct conversion paths analyzed

### 4. Detailed Conversion Ladder Analysis
For each offer:
- All 8 steps analyzed
- Drop-off risks identified
- Success indicators noted
- Estimated pass rate at each step
- Optimization opportunities listed

### 5. Conversion Rate Summary Table
- Current conversion for each offer
- Bottleneck identified
- Priority ranking

### 6. Universal Insights
- Common patterns
- What works well
- What fails consistently
- Structural issues

### 7. Implementation Roadmap (Phased)
- Phase 1 (Critical)
- Phase 2 (High)
- Phase 3 (Medium)
- Phase 4 (Optimization)

For each fix:
- What to change
- Where to change
- Impact estimate
- Effort estimate

### 8. Expected Improvements
- Before/after conversion table
- Overall improvement estimate (e.g., +300% conversion)

---

## Part 4: Key Principles for Analysis

### Principle 1: Be Specific, Not Generic
❌ Bad: "The site needs better content"
✅ Good: "Add detailed product specifications with images to product pages (currently missing), which will improve Step 3 (Comprehension) from 40% to 70%"

### Principle 2: Estimate Realistically
- Use evidence from the site structure
- Note when information is missing
- Acknowledge uncertainty
- Base estimates on common conversion patterns

### Principle 3: Focus on Biggest Bottlenecks First
- A step at 30% pass rate is more critical than one at 70%
- Improving 30%→70% has more impact than 70%→85%
- Prioritize fixes that affect multiple offers

### Principle 4: Consider User Psychology
- People are rational buyers for most products (need information)
- People are emotional buyers for some products (need feeling)
- Different segments have different needs
- Match messaging to psychological state

### Principle 5: Make Actionable Recommendations
Every finding should lead to a specific, implementable fix:
- ❌ "Navigation is confusing"
- ✅ "Add 'Featured Products' section on homepage linking to top 5 product detail pages"

### Principle 6: Think in Terms of Multiplication
Conversion = Step1 × Step2 × Step3 × Step4 × Step5 × Step6 × Step7 × Step8

Improving any step improves the whole funnel.
Improving the weakest step has the biggest impact.

### Principle 7: Distinguish Browsing from Buying
Not all traffic should convert:
- Some users are just researching
- Some users aren't in the target segment
- Some users aren't ready yet

Focus on:
- Converting ready buyers (high intent)
- Nurturing potential buyers (medium intent)
- Not wasting effort on non-buyers (wrong segment)

---

## Part 5: Common Bottlenecks by Industry

### E-commerce
**Most common bottleneck:** Step 3 (Comprehension)
- Insufficient product images
- Missing specifications
- No sizing guides
- Unclear shipping/returns

### SaaS
**Most common bottleneck:** Step 3 (Comprehension) & Step 4 (Belief)
- Vague feature descriptions
- No product demo visible
- Unclear pricing
- No social proof/testimonials

### Service Businesses
**Most common bottleneck:** Step 3 (Comprehension) & Step 4 (Belief)
- Abstract service descriptions
- No portfolio/examples
- Unclear deliverables
- No case studies

### B2B
**Most common bottleneck:** Step 4 (Belief) & Step 5 (Desire)
- Generic value propositions
- No ROI case studies
- Missing credentials
- Unclear differentiation

### Content/Education
**Most common bottleneck:** Step 5 (Desire) & Step 6 (Urgency)
- Benefits not compelling enough
- No reason to buy now vs later
- Unclear transformation
- Missing outcome demonstrations

---

## Part 6: Instructions for Claude Code

When this template is copied into a new project:

1. **Read the project structure:**
   - Identify main pages (homepage, product pages, category pages, etc.)
   - Map navigation structure
   - Identify all CTAs and conversion points
   - Note available content (images, text, forms, etc.)

2. **Identify business model:**
   - E-commerce, SaaS, Service, Content, B2B, B2C, Marketplace?
   - What are the conversion goals?
   - Who are the target customers?

3. **Map conversion paths:**
   - How do users enter the site?
   - What paths lead to conversion?
   - Where are the decision points?

4. **Apply the 8-step framework:**
   - Analyze each path through all 8 steps
   - Estimate pass rates based on content quality
   - Identify bottlenecks

5. **Define user segments:**
   - Based on entry points, intent, and behavior
   - 4-8 segments with distinct needs

6. **Create prioritized roadmap:**
   - Focus on biggest bottlenecks
   - Provide specific, actionable fixes
   - Estimate impact

7. **Output comprehensive analysis:**
   - Follow the output format in Part 3
   - Be specific and actionable
   - Include examples and evidence

---

## Part 7: Example Prompts for Using This Framework

### Initial Analysis:
> "Analyze this project using the CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md. Create a complete conversion analysis specific to this project."

### Deep Dive on Specific Offer:
> "Using the conversion ladder framework, do a detailed analysis of the [specific product/service] conversion path."

### Focus on Specific Step:
> "Analyze Step 3 (Comprehension) across all offers using the conversion ladder framework. What's preventing users from understanding our offer?"

### Segment Analysis:
> "Using the conversion ladder framework, analyze how [specific user segment] moves through our funnel differently than other segments."

### Implementation Planning:
> "Based on the conversion ladder analysis, create a detailed implementation plan for Phase 1 fixes with specific technical requirements."

---

## Part 8: Success Metrics to Track

After implementing fixes, track these metrics:

### Overall Metrics:
- [ ] Overall conversion rate
- [ ] Bounce rate (Step 1 failure)
- [ ] Scroll depth (Step 2 engagement)
- [ ] Time on page (Step 2-3)
- [ ] Detail page views (Step 3 comprehension)
- [ ] CTA click rate (Step 7 intent)
- [ ] Form completion rate (Step 8 action)

### Step-Specific Metrics:
- **Step 1:** Bounce rate, time to first interaction
- **Step 2:** Scroll depth, page views per session
- **Step 3:** Detail page views, FAQ views, video plays
- **Step 4:** Testimonial section views, trust badge clicks
- **Step 5:** Add to cart rate, wishlist additions
- **Step 6:** Conversion within 24h vs later visits
- **Step 7:** CTA click rate, contact form starts
- **Step 8:** Form completion rate, checkout completion

### Segment-Specific Metrics:
- Track metrics by traffic source (segment proxy)
- Compare conversion rates across segments
- Identify which segments improved most

---

## Part 9: Advanced Techniques

### Technique 1: Multi-Path Analysis
Some users take non-linear paths:
- Home → Product → Home → Category → Product → Purchase
- Analyze common sequences
- Optimize for actual behavior, not assumed behavior

### Technique 2: Micro-Conversions
Track smaller commitments that lead to final conversion:
- Email signup (captures future conversion)
- Account creation (higher commitment)
- Wishlist addition (desire confirmed)
- Demo video view (comprehension + engagement)

### Technique 3: Exit-Intent Analysis
When users leave at each step, understand why:
- Exit polls or surveys
- Heatmaps and session recordings
- A/B testing variations

### Technique 4: Competitive Analysis
Compare your 8-step performance to competitors:
- Which steps do they do better?
- What can you learn from their approach?
- Where can you differentiate?

### Technique 5: Cohort Analysis
Track different cohorts through the funnel:
- New vs returning visitors
- Different acquisition channels
- Different time periods
- Different device types

---

## Conclusion

This framework provides a systematic approach to understanding and optimizing any conversion funnel by:

1. **Mapping user psychology** through 8 distinct steps
2. **Identifying drop-off points** with estimated impact
3. **Prioritizing fixes** based on bottleneck severity
4. **Projecting improvements** with realistic estimates
5. **Creating actionable roadmaps** for implementation

**Key insight:** Most websites lose users at Step 3 (Comprehension) or Step 4 (Belief). Focus there first.

**Remember:** Conversion optimization is about:
- Reducing friction at every step
- Providing information when users need it
- Building trust progressively
- Making the next step obvious
- Removing barriers to action

---

**Ready to analyze a new project?**

Copy this template into your project folder and run:
> "Analyze this project using CONVERSION_LADDER_FRAMEWORK_TEMPLATE.md and create a complete conversion optimization analysis."
