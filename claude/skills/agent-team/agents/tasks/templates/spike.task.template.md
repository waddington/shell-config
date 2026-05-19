# Spike / Investigation Task Template

This template is used for time-boxed investigation and research tasks. It inherits every field from the general-purpose task template (`task.template.md`) and adds spike-specific fields that enforce bounded exploration and structured outcomes.

Spikes exist to answer questions, not to produce production code. They reduce uncertainty so that follow-up implementation tasks can be properly scoped and estimated.

---

## Inherited Fields

All fields from `task.template.md` are required. The following values are pre-set for spike tasks:

- **Type**: Always `spike` (overrides the general template's type options for this template).
- **Title**: Format: "Spike: [question to be answered]" (e.g., "Spike: Evaluate caching strategies for card lookup endpoint")
- **Labels**: Must include `spike` type label. Size label is required and represents the time box, not implementation complexity.
- **Required Review Gates**: Spikes do NOT go through code review gates. They produce documents, prototypes, and recommendations -- not production code. The Lead reviews the spike outcome directly. Set to `lead` only.

---

## Additional Required Fields

### Spike Goal
A clear, specific question that the spike must answer. The spike is complete when this question has been answered with sufficient confidence.

Rules:
1. Must be phrased as a question.
2. Must be answerable (not open-ended philosophy).
3. Must have a finite scope.

Good examples:
- "Can we use Redis for session caching without exceeding our current infrastructure budget?"
- "What is the performance impact of switching from JSON to Protobuf serialization for the card data pipeline?"
- "Which rate limiting library best fits our tech stack and latency requirements?"

Bad examples:
- "Investigate caching." (Not a question, no success criteria)
- "What is the best architecture?" (Too broad, subjective)
- "Learn about Kafka." (Learning is not a deliverable)

### Time Box
The maximum time or effort allowed for this spike. Spikes MUST be bounded to prevent unbounded exploration.

Format: A size (`XS`, `S`, `M`, `L`) with an explicit maximum duration.

- `XS` -- Up to half a unit of effort. Quick investigation, answer expected within a focused session.
- `S` -- 1-2 units of effort. May involve prototyping or benchmarking.
- `M` -- 3-5 units of effort. Significant investigation with multiple research areas.
- `L` -- 6-10 units of effort. Major investigation. Must be justified by the Lead.

**Spikes may NOT be sized `XL`.** If an investigation requires more than `L` effort, it must be split into multiple smaller spikes with more focused questions.

When the time box expires, the spike is complete regardless of whether the question is fully answered. The outcome document must state what was learned and what remains unknown.

### Research Areas
Enumerated list of specific areas to investigate. Provides structure to the investigation and helps the assignee stay focused within the time box.

Example:
```
1. Evaluate Redis vs Memcached for session caching (latency, memory footprint, operational complexity)
2. Assess infrastructure cost impact (current AWS ElastiCache pricing, projected usage)
3. Prototype cache invalidation strategy for card data updates
4. Review existing codebase for cache-friendly interfaces
```

### Decision Criteria
How the spike outcome will be evaluated. These are the criteria by which the Lead (and the team) will assess the spike's recommendation.

Must be concrete and measurable where possible.

Example:
```
1. Latency: p99 lookup latency must remain below 50ms with caching enabled.
2. Cost: Monthly infrastructure cost increase must not exceed $500.
3. Operational complexity: Solution must not require a dedicated operations team.
4. Compatibility: Solution must integrate with our existing Scala/Akka stack without major refactoring.
```

### Expected Deliverables
What the spike must produce. Spikes produce documents, prototypes, and recommendations -- NOT production code.

Common deliverables:
- **Decision document**: Analysis with pros/cons and a recommendation.
- **Prototype**: Throwaway proof-of-concept that demonstrates feasibility. Must be clearly marked as non-production code and must not be merged to the main branch.
- **Benchmark results**: Performance measurements with methodology documented.
- **Recommendation**: Clear recommendation with confidence level and supporting evidence.
- **Risk assessment**: Identified risks of the recommended approach.

Example:
```
1. Decision document comparing Redis vs Memcached (pros, cons, cost analysis)
2. Prototype demonstrating cache integration with CardService (throwaway, in spike branch only)
3. Benchmark results: latency measurements for cache hit/miss scenarios under load
4. Final recommendation with HIGH/MEDIUM/LOW confidence rating
```

### Follow-Up Tasks
Proposed tasks that should be created based on the spike findings. This field is blank when the spike is created and filled upon completion.

Each proposed follow-up should include:
- Proposed title
- Proposed type
- Estimated complexity
- Rationale (how it connects to the spike findings)

Example:
```
1. "Implement Redis caching for CardService lookups" (feature, M) -- spike confirmed Redis as the best option
2. "Add cache invalidation on card update events" (feature, S) -- required for data consistency per spike findings
3. "Update monitoring dashboards to include cache metrics" (chore, XS) -- recommended by spike for observability
```

Follow-up tasks are proposed via `TASK_PROPOSAL` messages to the Lead, who decides whether to accept them.

### Spike Outcome
Filled upon completion of the spike. This is the primary deliverable. Must include:

- **Findings**: Summary of what was learned during the investigation. Factual, evidence-based.
- **Recommendation**: The spike's answer to the Spike Goal question. Must directly address the original question.
- **Confidence Level**: `HIGH`, `MEDIUM`, or `LOW`
  - `HIGH`: Strong evidence supports the recommendation. Multiple data points agree. Low risk of the recommendation being wrong.
  - `MEDIUM`: Evidence supports the recommendation but with caveats. Some assumptions remain unvalidated.
  - `LOW`: Insufficient evidence for a strong recommendation. Further investigation may be needed.
- **Open Questions**: Questions that remain unanswered after the time box expired. These may inform follow-up spikes.
- **Artifacts Produced**: Links to decision documents, prototype branches, benchmark data.

Example:
```
Findings:
  - Redis outperforms Memcached by 30% for our access patterns (read-heavy, small payloads).
  - AWS ElastiCache Redis pricing for our projected usage: ~$200/month.
  - Cache invalidation can be triggered via existing Kafka card-update events.
  - Prototype demonstrated p99 latency of 12ms (vs current 45ms) for cached lookups.

Recommendation: Use Redis via AWS ElastiCache for CardService caching.

Confidence Level: HIGH

Open Questions:
  - What is the impact on cold-start scenarios when the cache is empty after deployment?

Artifacts Produced:
  - Decision document: agent-docs/spikes/TASK-0039-caching-decision.md
  - Prototype branch: spike/TASK-0039-redis-prototype (DO NOT MERGE)
  - Benchmark data: agent-docs/spikes/TASK-0039-benchmark-results.csv
```

---

## Important Notes

1. **Spikes do NOT go through code review gates.** They are reviewed by the Lead directly. The Lead evaluates the spike outcome against the decision criteria and spike goal.
2. **Spike prototypes are throwaway code.** They must never be merged to `develop` or `main`. They exist solely to demonstrate feasibility. Production implementation is a separate follow-up task.
3. **The time box is a hard boundary.** When it expires, the spike is complete. Document what you know and what you do not know. An incomplete answer with honest confidence assessment is better than exceeding the time box.
4. **Spikes reduce uncertainty.** If a spike does not reduce uncertainty (the question is just as unclear after the spike as before), the spike has failed. Document why and propose a different approach.

---

## Blank Template

```
[All fields from task.template.md, plus:]

Spike Goal: [specific question to answer]
Time Box: [XS | S | M | L] -- [maximum duration description]
Research Areas:
  1. [area to investigate]
  2. [area to investigate]
Decision Criteria:
  1. [measurable criterion]
  2. [measurable criterion]
Expected Deliverables:
  1. [deliverable]
  2. [deliverable]
Follow-Up Tasks: [blank until spike completion]
Spike Outcome:
  Findings: [blank until spike completion]
  Recommendation: [blank until spike completion]
  Confidence Level: [blank until spike completion]
  Open Questions: [blank until spike completion]
  Artifacts Produced: [blank until spike completion]
```
