# API Guidelines

**Enforced by:** `reviewer.standards` (convention compliance), `architect.principal` (design decisions)
**Scope:** All HTTP APIs exposed by this service, internal and external.

> **TODO:** These guidelines are a starting point and require significant refinement. A human must review and rewrite these standards based on actual CK API conventions, internal style guides, existing service patterns, and any documented API governance from CK repos and engineering guidelines. Do not treat these as authoritative without that review.

---

## 1. RESTful Design

### 1.1 Resource Naming

Plural nouns, lowercase, hyphen-separated. Represent domain entities, not database tables.

- Correct: `/api/v1/wallet-provisions`, `/api/v1/card-tokens`
- Incorrect: `/api/v1/walletProvision`, `/api/v1/Card`, `/api/v1/getCards`

Finding: SHOULD_FIX.

### 1.2 URL Structure

Pattern: `/api/v{version}/{resource}/{id}/{sub-resource}/{sub-id}`

- Version is a positive integer: `v1`, `v2`. Not `v1.1` or `v1-beta`.
- Resource IDs are path parameters, not query parameters.
- Sub-resources express parent-child: `/api/v1/cards/{cardId}/tokens`.
- Max nesting depth: 2 levels. Deeper nesting must be flattened or use a top-level resource with filters.
- No trailing slashes. No file extensions (`.json`, `.xml`).

Finding: SHOULD_FIX.

### 1.3 HTTP Methods

| Method | Purpose | Body | Idempotent | Safe | Success Code |
|--------|---------|------|-----------|------|-------------|
| GET | Retrieve | No | Yes | Yes | 200 |
| POST | Create or trigger action | Yes | No | No | 201 (create), 200/202 (action) |
| PUT | Full replacement | Yes | Yes | No | 200 |
| PATCH | Partial update | Yes | Yes | No | 200 |
| DELETE | Remove | No | Yes | No | 204 |

- GET must never modify state. **MUST_FIX.**
- POST for creation must return the created resource with its assigned ID. SHOULD_FIX.
- PUT requires the full resource in the request body; omitted fields are set to defaults. SHOULD_FIX.
- DELETE must be idempotent — deleting a non-existent resource returns 204, not 404. SHOULD_FIX.

### 1.4 Idempotency

PUT, PATCH, and DELETE must be idempotent. POST operations with side effects beyond creation should support an `Idempotency-Key` header. Finding for non-idempotent PUT/PATCH/DELETE: **MUST_FIX.**

---

## 2. Request/Response Standards

### 2.1 Content Type

All request/response bodies use `application/json`. `Content-Type` is required on all requests with a body. Non-JSON endpoints must document the deviation.

### 2.2 Response Envelope

**Success:** `{ "data": <object or array>, "metadata": <optional> }`

**Error:** `{ "errors": [ { "code": "UPPER_SNAKE_CASE", "message": "...", "details": <optional>, "requestId": "..." } ] }`

`data` and `errors` must not appear in the same response. Finding: SHOULD_FIX.

### 2.3 Pagination

**Cursor-based** (preferred for all list endpoints): `limit` (default 20, max 100), `cursor`. Response metadata: `nextCursor`, `hasMore`.

**Offset-based** (acceptable for random-access endpoints): `limit`, `offset`. Response metadata: `total`, `limit`, `offset`.

Unpaginated list endpoints that can return unbounded results: **MUST_FIX.**

### 2.4 Filtering

Query parameters matching resource field names: `GET /api/v1/cards?status=active&type=virtual`. Multiple values comma-separated: `status=active,pending`. Finding for inconsistent naming: NITPICK.

### 2.5 Sorting

`sort` query parameter, format `field:direction` (`asc`/`desc`, default `asc`). Multiple fields comma-separated: `sort=createdAt:desc,name:asc`. Every list endpoint must document its default sort order. Finding for undocumented default: SHOULD_FIX.

---

## 3. Status Codes

### 3.1 Success

| Code | Usage |
|------|-------|
| 200 | Successful GET, PUT, PATCH, or action POST |
| 201 | Resource creation POST — must include `Location` header |
| 202 | Async operation accepted |
| 204 | Successful DELETE or no-body operation |

### 3.2 Client Errors

| Code | Usage |
|------|-------|
| 400 | Malformed request, invalid field values, constraint violations |
| 401 | Missing or invalid authentication |
| 403 | Valid credentials, insufficient permissions |
| 404 | Resource does not exist |
| 405 | HTTP method not supported |
| 409 | Conflict with current resource state |
| 422 | Syntactically valid but semantically invalid (business rule violation) |
| 429 | Rate limit exceeded — must include `Retry-After` header |

### 3.3 Server Errors

| Code | Usage |
|------|-------|
| 500 | Unhandled server error — never expose stack traces or internal details |
| 502 | Upstream returned invalid response |
| 503 | Service unavailable — must include `Retry-After` header |
| 504 | Upstream timed out |

- Never return 200 with an error body. **MUST_FIX.**
- Never return 500 for client errors. **MUST_FIX.**
- Never expose stack traces, class names, or implementation details in error responses. **MUST_FIX.**

---

## 4. Versioning

URL-based: `/api/v1/`, `/api/v2/`. No header or query-parameter versioning.

**Breaking changes** (require a new API version):
- Removing or renaming a response field
- Changing a field's type or semantics
- Making an optional field required
- Removing an endpoint or changing its URL
- Changing authentication requirements

Finding for unversioned breaking change: **MUST_FIX.**

**Non-breaking changes** (no new version needed):
- Adding optional request fields or query parameters
- Adding response fields
- Adding new endpoints or enum values (if consumers handle unknowns gracefully)

**Deprecation:** Deprecated versions must remain functional for at least 6 months after the replacement is available. Deprecated endpoints must return a `Deprecation` header with the sunset date and all known consumers must be notified before sunset. Finding for removing deprecated API before sunset: **MUST_FIX.**

---

## 5. Authentication and Authorization

- Every endpoint requires authentication unless explicitly documented as public. Public endpoints require `reviewer.security` approval. Finding for unapproved unauthenticated endpoint: **MUST_FIX.**
- Authorization must be checked in the request handler, not middleware only. Middleware cannot enforce resource-level permissions. Finding for missing resource-level authorization: **MUST_FIX.**
- Bearer tokens validated on every request: signature, expiration, issuer, audience, required scopes. Finding for incomplete token validation: **MUST_FIX.**
- All public-facing endpoints must have rate limiting (per-client). 429 response must include `Retry-After` and `X-RateLimit-Remaining`. Finding: SHOULD_FIX.

---

## 6. Documentation

Every endpoint must document: HTTP method and path, description, auth requirements and scopes, request body schema (types, required/optional, constraints, examples), response schema per status code, error codes, and example request/response.

Finding for undocumented endpoints: **MUST_FIX** (external), SHOULD_FIX (internal).

All schemas must be machine-readable (OpenAPI/JSON Schema) with types, required/optional markers, format constraints, descriptions, and examples. Finding: SHOULD_FIX.
