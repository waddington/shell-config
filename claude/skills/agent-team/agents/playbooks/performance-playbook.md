# Performance Playbook

Authoritative reference for the `perf.reliability` role and for Lead when managing performance-related work.

---

## 1. Performance Review Triggers

Lead MUST assign `perf.reliability` to the review when any of these triggers are present. When uncertain, assign.

| # | Trigger | Review Scope |
|---|---------|-------------|
| 1 | New database query | Query plan, execution time, index usage, result set size |
| 2 | Modified database query | Same as new query + regression vs. prior performance |
| 3 | New API endpoint | Response time projection, expected load, resource consumption |
| 4 | Batch/bulk operations | Batch size limits, memory usage, processing time scaling |
| 5 | File I/O operations | Buffer sizing, stream handling, resource cleanup |
| 6 | Memory-intensive operations | Memory footprint, growth patterns, GC pressure |
| 7 | Hot path changes | Latency impact, throughput impact, CPU usage |
| 8 | Infrastructure/platform changes | Resource allocation adequacy, scaling behavior |
| 9 | New external service call | Latency budget impact, timeout config, circuit breaker, retry policy |
| 10 | Caching changes | Cache hit rate, eviction policy, memory impact, stale data risk |
| 11 | Concurrency changes | Thread contention, deadlock risk, resource exhaustion |
| 12 | Algorithm changes | Time complexity, space complexity, behavior at scale |

Check triggers at task creation and again when `TASK_DONE` is received.

---

## 2. Performance Budgets

Exceeding a budget is a `MUST_FIX` finding.

### 2.1 API Response Time

| Operation Type | P50 | P95 | P99 | Max |
|---------------|-----|-----|-----|-----|
| Read (single resource) | < 50ms | < 200ms | < 500ms | 1000ms |
| Read (collection/list) | < 100ms | < 300ms | < 800ms | 1500ms |
| Write (POST/PUT/PATCH) | < 100ms | < 500ms | < 1000ms | 2000ms |
| Delete | < 50ms | < 200ms | < 500ms | 1000ms |
| Search/filter | < 200ms | < 500ms | < 1000ms | 2000ms |

Application layer only (excludes network transit and external service latency).

### 2.2 Database Query

| Query Type | P50 | P95 | Max |
|-----------|-----|-----|-----|
| Single-row by primary key | < 5ms | < 20ms | 50ms |
| Single-row by indexed column | < 10ms | < 30ms | 100ms |
| Multi-row with index | < 20ms | < 50ms | 200ms |
| Aggregation | < 50ms | < 100ms | 500ms |
| Full table scan | **NOT PERMITTED** in production | | |

Full table scans are `MUST_FIX` unless the table is documented to be small and bounded (< 1000 rows). Queries returning > 1000 rows must use pagination.

### 2.3 Batch Operations

| Constraint | Requirement |
|-----------|-------------|
| Batch size | Configurable — not hardcoded. Default max: 100 records. |
| Memory | Must not load entire dataset into memory — stream or paginate. |
| Progress reporting | Required for batches of 1000+ records. |
| Error handling | Individual item failure must not fail the entire batch (unless business logic requires it). |

### 2.4 External Service Calls

| Constraint | Requirement |
|-----------|-------------|
| Connection timeout | Required. Default: 5s. |
| Read timeout | Required. Default: 10s. |
| Circuit breaker | Required for all external calls. Opens after 5 consecutive failures. |
| Retry policy | Max 3 retries with exponential backoff (1s, 2s, 4s). |
| Fallback | Must have defined fallback (cached data, default, or graceful failure). |

### 2.5 Memory

| Constraint | Requirement |
|-----------|-------------|
| Unbounded growth | No collection or data structure may grow without bound. |
| Large objects (> 1MB) | Must be streaming-based, not loaded entirely into memory. |
| Caches | Must have configured max size and eviction policy. |
| Connection pools | Must have configured maximum size. |

### 2.6 Frontend Bundle

| Constraint | Requirement |
|-----------|-------------|
| Per-feature delta | < 10KB compressed. |
| Total bundle | Report any increase > 5%. |

---

## 3. Regression Detection

### 3.1 Regression Severity

| Magnitude | Severity | Action |
|-----------|----------|--------|
| > 50% latency increase | Sev1 | `MUST_FIX`. Change blocked. Lead notifies human. |
| 10–50% latency increase | Sev2 | `MUST_FIX`. Change blocked until addressed or explicitly accepted. |
| 5–10% latency increase | Sev3 | `SHOULD_FIX`. May proceed with a follow-up optimization task. |
| < 5% latency increase | Informational | Track in metrics. No action. |
| Latency decrease | Positive | Note in review. No action. |

### 3.2 Detection Procedure

1. Identify code paths affected by the change.
2. Measure or estimate performance of those paths after the change.
3. Compare against baseline (production metrics, prior benchmark results).
4. Classify per the table above.
5. For Sev1/Sev2 findings, include in `REVIEW_RESULT`: before value, after value, % delta, root cause, and specific fix recommendation.

A regression may be accepted (not fixed) only if: it is Sev3 or lower, the business value justifies the cost, `perf.reliability` documents it, a follow-up optimization task is created, and Lead explicitly approves.

---

## 4. Required Instrumentation

Missing instrumentation = `SHOULD_FIX`. Naming convention: `service_name.component.metric_name.unit`.

| Change Type | Required Instruments |
|------------|---------------------|
| New API endpoint | Request latency (Histogram), request count (Counter), error rate by status (Counter), active requests (Gauge) |
| New/modified DB query | Query execution time (Histogram), result set size (Histogram), query error count (Counter) |
| New external service call | Call latency (Histogram), success/failure rate (Counter), circuit breaker state (Gauge), retry count (Counter) |
| New background job | Job duration (Histogram), job failure count (Counter), items processed (Counter) |
| New cache | Cache hits/misses (Counter), cache size (Gauge), eviction count (Counter) |

---

## 5. Performance Review Checklist

**Database:**
- [ ] Queries use appropriate indexes — no full table scans
- [ ] No N+1 query patterns
- [ ] Pagination used for large result sets
- [ ] Transactions scoped minimally (no long-running transactions)
- [ ] Bulk operations use batch inserts/updates, not loops of individual calls

**API:**
- [ ] Response time within budget for operation type
- [ ] Response payload size is reasonable (no over-fetching)
- [ ] Compression enabled for large responses

**Memory:**
- [ ] No unbounded collections
- [ ] Large objects are streamed, not loaded into memory entirely
- [ ] Resources (connections, streams, file handles) are properly closed
- [ ] Cache sizes are bounded with eviction policies

**Concurrency:**
- [ ] Thread pools and connection pools are bounded
- [ ] No busy-wait patterns
- [ ] Lock contention is minimised
- [ ] Deadlock potential assessed

**External calls:**
- [ ] Timeouts configured
- [ ] Circuit breakers in place
- [ ] Retry policies use exponential backoff
- [ ] Fallback behavior defined

**Algorithm:**
- [ ] Time complexity appropriate for expected data sizes
- [ ] No unnecessary sorting/filtering/transformation of large datasets

**Review output:** `REVIEW_RESULT` with `MUST_FIX` findings including specific budget exceeded and measured/estimated value; `SHOULD_FIX` findings with specific improvement and expected impact.

---

## 6. Escalation

| Finding | Action |
|---------|--------|
| > 50% latency regression (Sev1) | `ESCALATION: reason: PERFORMANCE` to Lead. Block merge. Lead notifies human. |
| 10–50% latency regression (Sev2) | `MUST_FIX` in review. Implementer addresses or justifies. |
| Full table scan in production query | `MUST_FIX` — add index or rewrite query. |
| Unbounded collection growth | `MUST_FIX` — add bounds. |
| Missing timeout on external call | `MUST_FIX` — add timeout configuration. |
| Missing circuit breaker | `SHOULD_FIX` — add circuit breaker. |
| Missing instrumentation | `SHOULD_FIX` — add instrumentation. |

---

## 7. Performance Testing

**Required for:** new endpoints expected to handle > 100 req/s; DB queries on tables with > 100K rows; batch operations processing > 1000 records; code paths within 50% of the performance budget limit.

**Not required for:** simple CRUD on small datasets, configuration changes, documentation changes, test-only changes.

| Test Type | Purpose | When to Use |
|----------|---------|-------------|
| Microbenchmark | Execution time of a specific method or block | Algorithm changes, hot path changes |
| Load test | System behavior under expected production load | New endpoints, infrastructure changes |
| Stress test | Find the system breaking point | Capacity planning, pre-release |
| Soak test | Behavior over extended time (memory leaks, resource exhaustion) | Background jobs, caching changes |

**Standards:** Tests must be deterministic within ±10% variance; run in isolation; measure wall-clock time; compare against a baseline; run in a dedicated perf stage, not standard CI.

---

## 8. Anti-Patterns

1. **Premature optimization** — optimizing unmeasured code. Measure first, then optimize bottlenecks.
2. **Unmeasured optimization** — claiming performance improvements without before/after measurements.
3. **Ignoring P99** — P99 represents 1 in 100 users. Tail latency matters.
4. **Unbounded everything** — collections, caches, pools, batch sizes without maximum limits.
5. **N+1 queries** — one query per item in a collection. Use batch queries or joins.
6. **Missing timeouts** — external calls without timeouts cascade into system-wide slowdown.
7. **Missing circuit breakers** — continuing to call a failing service wastes resources.
8. **Synchronous external calls in request path** — use async, caching, or queue-based patterns.
9. **Logging in hot paths** — verbose logging at high frequency. Use appropriate levels and sampling.
10. **Full table scans** — fine at 100 rows in dev, catastrophic at 10M rows in production.
11. **Memory leaks through event listeners** — registering callbacks without cleanup. Accumulate over time.
