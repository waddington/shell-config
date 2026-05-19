# Observability Playbook

Authoritative reference for the `observability` role and for Lead when managing observability-related work.

> **TODO:** Add CK-specific observability guidance covering New Relic dashboards and alerting, the observability MCP tool, CK logging pipelines, and standard patterns for Credit Karma services.

---

## 1. Observability Requirements by Change Type

Missing observability = `SHOULD_FIX`. Missing error logging for a new error path = `MUST_FIX`.

### 1.1 New API Endpoint

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| Request received | INFO | `method`, `path`, `request_id`, `user_id` (if authenticated) |
| Request completed | INFO | `method`, `path`, `status_code`, `duration_ms`, `request_id` |
| Request failed | ERROR | `method`, `path`, `status_code`, `error_code`, `error_message`, `request_id`, `stack_trace` |
| Validation failure | WARN | `method`, `path`, `validation_errors`, `request_id` |

**Metrics:**

| Metric | Type | Labels |
|--------|------|--------|
| Request latency | Histogram | `method`, `path`, `status_code` |
| Request count | Counter | `method`, `path`, `status_code` |
| Error count | Counter | `method`, `path`, `error_code` |
| Active requests | Gauge | `method`, `path` |

Health check: every new endpoint must be reachable via the existing health check mechanism. New dependencies must be verified in the health check.

### 1.2 New Background Job

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| Job started | INFO | `job_name`, `job_id`, `trigger`, `timestamp` |
| Job progress | INFO | `job_name`, `job_id`, `items_processed`, `items_total`, `elapsed_ms` |
| Job completed | INFO | `job_name`, `job_id`, `duration_ms`, `items_processed`, `status` |
| Job failed | ERROR | `job_name`, `job_id`, `error_code`, `error_message`, `items_processed_before_failure`, `stack_trace` |
| Retry attempt | WARN | `job_name`, `job_id`, `attempt_number`, `max_attempts`, `reason` |

**Metrics:**

| Metric | Type | Labels |
|--------|------|--------|
| Job duration | Histogram | `job_name`, `status` |
| Job failure count | Counter | `job_name`, `error_code` |
| Items processed | Counter | `job_name`, `status` |
| Active jobs | Gauge | `job_name` |

### 1.3 Database Migration

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| Migration started | INFO | `migration_name`, `version`, `direction` |
| Migration completed | INFO | `migration_name`, `version`, `duration_ms`, `direction` |
| Migration failed | ERROR | `migration_name`, `version`, `error_message`, `stack_trace` |
| Rollback initiated | WARN | `migration_name`, `version`, `reason` |

No metrics required — migrations are one-time events.

### 1.4 New Error Path

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| Error occurred | ERROR | `error_code`, `error_message`, `context`, `request_id`, `user_id` (masked), `stack_trace` |
| Error recovered | WARN | `error_code`, `recovery_action`, `request_id` |
| Error escalated | ERROR | `error_code`, `escalation_target`, `request_id` |

**Metrics:** `error_count` counter with labels `error_code`, `component`.

Every new error path must include an alert consideration (see §5).

### 1.5 Configuration Change

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| Config loaded | INFO | `config_source`, `config_keys_loaded` (names only, NOT values) |
| Config validation failed | ERROR | `config_source`, `validation_errors` |
| Config value overridden | WARN | `config_key`, `override_source` |

### 1.6 New External Integration

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| External call initiated | DEBUG | `target_service`, `operation`, `request_id` |
| External call completed | INFO | `target_service`, `operation`, `status_code`, `duration_ms`, `request_id` |
| External call failed | ERROR | `target_service`, `operation`, `error_code`, `error_message`, `duration_ms`, `request_id` |
| Circuit breaker opened | WARN | `target_service`, `failure_count`, `threshold` |
| Retry attempted | WARN | `target_service`, `operation`, `attempt`, `max_attempts`, `reason` |

**Metrics:**

| Metric | Type | Labels |
|--------|------|--------|
| External call latency | Histogram | `target_service`, `operation`, `status` |
| External call count | Counter | `target_service`, `operation`, `status` |
| Circuit breaker state | Gauge | `target_service` |
| Retry count | Counter | `target_service`, `operation` |

### 1.7 Authentication/Authorization Events

**Logging:**

| Event | Level | Required Fields |
|-------|-------|----------------|
| Auth success | INFO | `user_id`, `auth_method`, `request_id` |
| Auth failure | WARN | `auth_method`, `failure_reason`, `source_ip`, `request_id` |
| Authz check failed | WARN | `user_id`, `resource`, `action`, `request_id` |
| Session created | INFO | `user_id`, `session_duration_config` |
| Session expired | INFO | `user_id`, `reason` |

**CRITICAL: NEVER log passwords, tokens, session IDs, or any credentials.**

---

## 2. Structured Logging Standards

All logs MUST be JSON. No unstructured text logs.

**Required fields (every log entry):**

| Field | Type | Description |
|-------|------|-------------|
| `timestamp` | ISO 8601 | When the entry was created |
| `level` | String | `DEBUG`, `INFO`, `WARN`, or `ERROR` |
| `message` | String | Human-readable event description |
| `service` | String | Service name |
| `trace_id` | String | Distributed tracing ID |
| `span_id` | String | Span ID within the trace |

**Contextual fields (when available):** `user_id`, `request_id`, `task_id`, `component`, `operation`.

**Log level guidelines:**

| Level | Use When |
|-------|----------|
| `DEBUG` | Detailed diagnostic info — not enabled in production by default |
| `INFO` | Normal operational events confirming the system works |
| `WARN` | Unexpected but recoverable events (retries, validation failures, circuit breaker) |
| `ERROR` | Failures preventing the current operation from completing |

**NEVER log:** passwords, API/session/bearer tokens, credit card numbers (beyond last 4), SSNs/government IDs, encryption keys, DB connection strings with credentials, unmasked email addresses. **Severity if violated: `MUST_FIX`. If in production: Sev1.**

**Log entry size limits:** max 10KB per entry, max 50 stack frames, collections as count/summary not full content.

---

## 3. Metric Standards

**Naming convention:** `service_name.component.metric_name.unit` — lowercase with underscores.

Example: `card_in_wallet.payment_service.request_latency.milliseconds`

**Metric types:**

| Type | Use When |
|------|----------|
| Counter | Counting events that only increase |
| Histogram | Measuring distributions (latency, response size) |
| Gauge | Measuring current state that can increase or decrease |

**Label rules:** max 5 labels per metric. NEVER use user IDs, request IDs, or timestamps as label values — these are unbounded and cause storage explosion. Acceptable labels: `method`, `status_code`, `error_code`, `operation` (known bounded sets only).

---

## 4. Tracing Requirements

- Every incoming HTTP request must have a `trace_id`. Generate one if not provided.
- `trace_id` must propagate to all downstream calls (DB queries, external calls, message queues).
- `trace_id` must appear in all log entries for that request.

Create spans for: each HTTP request, each DB query, each external service call, each significant internal operation.

Each span must include: `span_id`, `parent_span_id`, `operation_name`, `start_time`, `end_time`, `status`, `attributes` (relevant context without PII).

---

## 5. Alerting Readiness

Every new error path, metric, and external dependency must include an alert consideration documenting: what to alert on, threshold, severity (Sev0–Sev3), response action, and false positive risk.

**Standard alert templates:**

| Alert Pattern | Suggested Threshold | Severity |
|--------------|-------------------|----------|
| High error rate | > 1% for 5 min | Sev2 |
| Elevated error rate | > 5% for 2 min | Sev1 |
| Critical error rate | > 10% for 1 min | Sev0 |
| High latency (reads) | P95 > 200ms for 5 min | Sev2 |
| High latency (writes) | P95 > 500ms for 5 min | Sev2 |
| Very high latency | P99 > 2x budget for 2 min | Sev1 |
| Circuit breaker open | Any open | Sev2 |
| DB query slow | P95 > 50ms for 5 min | Sev2 |
| Memory growth | > 80% max heap | Sev2 |
| Job failure | Any failure | Sev3 (Sev1 for critical jobs) |
| Auth failure spike | 5x baseline in 5 min | Sev1 |

For each alert document: name, metric/log query, threshold and evaluation window, notification target, runbook link.

---

## 6. Review Process

**Review is triggered when:** new endpoint/job/integration introduced; new error path added; logging or metrics code modified; alert gap identified; Lead assigns per change type matrix.

**Review checklist:**

Logging:
- [ ] All required log events present for applicable change type (§1)
- [ ] JSON format
- [ ] All required fields included (§2)
- [ ] Log levels appropriate (§2)
- [ ] No PII or credentials in logs (§2)

Metrics:
- [ ] All required metrics present (§1)
- [ ] Naming convention followed (§3)
- [ ] Metric types appropriate (§3)
- [ ] Labels bounded and appropriate (§3)

Tracing:
- [ ] `trace_id` propagated through new code path
- [ ] Spans created for significant operations

Alerting:
- [ ] Alert considerations documented for new error paths and metrics

**Review output severity:**
- `MUST_FIX` — critical gap (no error logging for a new error path, PII in logs, no metrics for new endpoint).
- `SHOULD_FIX` — missing but non-critical (missing DEBUG logging, non-essential metric labels, missing alert consideration).
- `NITPICK` — minor improvements (log message wording, metric name refinement).

---

## 7. Observability Gap Remediation

**Gap detection triggers:** adjacent existing code identified during review; dedicated audit task; production incident reveals insufficient observability.

**When a gap is found:** send `TASK_PROPOSAL` to Lead describing the gap, its impact, and recommended remediation. Lead creates and assigns remediation task if accepted.

**Gap priority:** no error logging for production error path → P1. No metrics for high-traffic endpoint, missing trace propagation, missing alert for known failure → P2. Incomplete structured logging, missing debug logging, suboptimal naming → P3.

---

## 8. Anti-Patterns

1. **Log-and-forget** — logs without monitoring consumers are dead code.
2. **Metric explosion** — too many metrics or unbounded labels causes storage cost explosion.
3. **Logging PII** — violates privacy regulations and security policy. See §2.
4. **Wrong log level** — `ERROR` for expected conditions (validation failures are `WARN`); `INFO` for debug data.
5. **Unstructured logs** — text-based logs are unsearchable and unalertable.
6. **Missing trace context** — no `trace_id`/`request_id` makes cross-service correlation impossible.
7. **Alert fatigue** — thresholds too aggressive → frequent false positives → engineers ignore alerts.
8. **No alerting** — having metrics/logs but no alerts means problems are discovered by users.
9. **Observability as afterthought** — logging and metrics must be in the task's acceptance criteria, not added post-review.
10. **Logging secrets** — API keys, tokens, passwords, connection strings. Secret scanning helps but does not replace prevention.
11. **High-cardinality labels** — user IDs, request IDs, or timestamps as metric labels create unbounded series.
12. **Silent failures** — catching exceptions and discarding them without logging.
