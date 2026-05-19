# Logging and Metrics Standards

**Enforced by:** `observability`
**Scope:** All source code in this repository. No exceptions.

> **TODO:** These standards are a starting point and require significant refinement. A human must review and rewrite them based on actual CK logging pipelines, New Relic conventions, internal observability tooling, and patterns from CK repos and engineering guidelines. Do not treat these as authoritative without that review.

Missing logging for new endpoints: `MUST_FIX`. Logging sensitive data: `MUST_FIX`. Missing metrics for new features: `SHOULD_FIX`.

---

## Structured Logging

All log output MUST be in JSON format. Unstructured or plaintext log lines: `SHOULD_FIX`.

### Required Fields

| Field | Format | Description |
|---|---|---|
| `timestamp` | ISO 8601 (`2026-03-03T14:22:01.123Z`) | When the event occurred. UTC required. |
| `level` | String (`TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`) | Severity of the event. |
| `message` | String | Human-readable description of the event. |
| `service_name` | String | The name of the service emitting the log. |
| `trace_id` | String | Distributed trace identifier for request correlation. |
| `span_id` | String | Span identifier within the trace. |

### Optional Context Fields

| Field | Description |
|---|---|
| `user_id` | Anonymized identifier for the acting user. Never log raw PII. |
| `request_id` | Unique identifier for the incoming request. |
| `task_id` | Reference to the task or ticket that initiated the work. |
| `correlation_id` | Identifier linking related operations across services. |

### Log Level Usage

- **TRACE** — Fine-grained debugging detail. MUST be disabled in production.
- **DEBUG** — Diagnostic information for development and troubleshooting. MUST be disabled in production.
- **INFO** — Business events, request lifecycle markers, state transitions. Default production level.
- **WARN** — Recoverable issues: deprecated API usage, approaching resource limits, retry attempts, fallback activation.
- **ERROR** — Failures requiring attention. Operation could not complete as intended.
- **FATAL** — Unrecoverable failures. Service cannot continue operating.

Misuse of log levels: `NITPICK`.

---

## What to Log

Missing any of the following in new code: `MUST_FIX`.

- **Request received (INFO):** HTTP method, request path, anonymized client info. Do not log request bodies by default.
- **Request completed (INFO):** Response status code, request duration (ms), response size (bytes).
- **External service calls (INFO):** Target service name, operation, call duration (ms), success/failure.
- **Error conditions (ERROR):** Error type, message, stack trace, and all available context (request ID, trace ID, operation).
- **Security events (WARN/ERROR):** Authentication failures (WARN), permission denials, rate limit triggers, suspicious patterns. Repeated auth failures from same source: ERROR.
- **State transitions (INFO):** Significant business state changes (e.g., card status transitions). Include previous state, new state, and trigger.
- **Configuration loaded (INFO):** Configuration source and non-sensitive values at startup. Never log secrets or connection strings.
- **Background job lifecycle (INFO):** Job start, completion, failure, retry. Include job name, duration, outcome. Exhausted retries: ERROR.

---

## What NEVER to Log

Each of the following is a `MUST_FIX` regardless of log level.

- **Passwords, tokens, API keys, or secrets** — Logging creates a persistent, broadly-accessible copy of credentials.
- **Credit card numbers, SSNs, or full bank account numbers** — Regulated data subject to PCI-DSS and similar frameworks.
- **Raw PII (names, emails, addresses, phone numbers)** — Use anonymized identifiers. Log `user_id`, not the user's email.
- **`numericId`** — Raw numeric user identifier; never log. `dwNumericId` is acceptable.
- **Full request or response bodies containing sensitive data** — If logging a body for debugging, redact sensitive fields first. Use `DEBUG` level with redaction, disabled in production.
- **Session tokens or authentication tokens** — Log a token fingerprint (last 4 characters) if correlation is needed.
- **Database connection strings with credentials** — Log host and database name only.

---

## Metrics Standards

### Naming Convention

Pattern: `service_name.component.metric_name.unit`

Examples: `ciw.api.request_duration.ms`, `ciw.db.query_count.total`, `ciw.cache.hit_count.total`

### Metric Types

- **Counters** — Events that only increase: request counts, error counts, job completions.
- **Histograms** — Distributions: request durations, response sizes. Provides p50/p95/p99.
- **Gauges** — Point-in-time values: connection pool size, active thread count, queue length.

### Required Metrics by Component

**API endpoints** (missing any: `SHOULD_FIX`):

| Metric | Type | Description |
|---|---|---|
| `request_count` | Counter | Total requests, tagged by endpoint and method. |
| `request_duration_ms` | Histogram | Time from request received to response sent. |
| `error_count` | Counter | Total error responses, tagged by endpoint and error type. |

**Background jobs:**

| Metric | Type | Description |
|---|---|---|
| `job_count` | Counter | Total executions, tagged by job name. |
| `job_duration_ms` | Histogram | Time from start to completion. |
| `job_failure_count` | Counter | Total failures, tagged by job name and failure reason. |

**External service calls:**

| Metric | Type | Description |
|---|---|---|
| `call_count` | Counter | Total outbound calls, tagged by target service and operation. |
| `call_duration_ms` | Histogram | Round-trip time. |
| `call_error_count` | Counter | Total failed calls, tagged by target service and error type. |

**Database queries:**

| Metric | Type | Description |
|---|---|---|
| `query_count` | Counter | Total queries, tagged by type (select, insert, update, delete). |
| `query_duration_ms` | Histogram | Time from submission to result receipt. |

**Caches:**

| Metric | Type | Description |
|---|---|---|
| `cache_hit_count` | Counter | Total hits, tagged by cache name. |
| `cache_miss_count` | Counter | Total misses, tagged by cache name. |
| `cache_eviction_count` | Counter | Total evictions, tagged by cache name and reason. |

---

## Alerting Readiness

- Every `ERROR`-level log MUST have a corresponding alert consideration documented. If the error is expected under certain conditions, document why it does not need an alert.
- Metrics MUST have documented warning and critical thresholds. Thresholds belong in the service's runbook, not in the code.
- Alerts MUST be actionable. Non-actionable alerts are noise — make them dashboard metrics instead.

| Field | Description |
|---|---|
| `metric` | The metric being monitored. |
| `threshold_warning` | Value at which a warning is raised. |
| `threshold_critical` | Value at which a critical alert fires. |
| `runbook_link` | Link to runbook with investigation and remediation steps. |

---

## Health Checks

- Every service MUST expose a health check endpoint (e.g., `/health` or `/status`).
- Health checks MUST verify downstream dependencies (database, external services, cache).
- Health checks MUST NOT have side effects or require authentication.
- Required response fields:

| Field | Description |
|---|---|
| `status` | Overall health: `UP`, `DEGRADED`, or `DOWN`. |
| `version` | Deployed version of the service. |
| `uptime` | Duration since service started. |
| `dependency_statuses` | Map of dependency name to health status. |
