# Architecture Standards

**Enforced by:** `architect.principal`
**Severity model:** Sev0-Sev3. Findings: MUST_FIX, SHOULD_FIX, NITPICK, PRAISE.
**Scope:** All architectural decisions, service boundaries, dependency choices, and structural patterns in this repository.

> **TODO:** These standards are a starting point and require significant refinement. A human must review and rewrite them based on actual CK architectural patterns, service topology, internal engineering guidelines, and conventions from CK repos. Do not treat these as authoritative without that review.

---

## 1. Layered Architecture

### 1.1 Layer Definitions

| Layer | Responsibility | Examples |
|---|---|---|
| Presentation | HTTP handlers, request/response serialization, input validation | Controllers, routes, API endpoint definitions |
| Application / Service | Use case orchestration, transaction boundaries, cross-domain coordination | Service classes, use case classes |
| Domain | Business rules, domain entities, value objects, domain events | Models, domain services, domain errors |
| Infrastructure | External system integration, persistence, messaging, caching | Repository implementations, HTTP clients, queue producers/consumers |

### 1.2 Dependency Direction

Dependencies point inward: Presentation → Application → Domain ← Infrastructure. The domain layer has zero external dependencies. Infrastructure implements interfaces defined in the domain layer (dependency inversion).

**Prohibited:**
- Presentation importing Infrastructure directly. Finding: MUST_FIX.
- Domain importing Application, Presentation, or Infrastructure. Finding: MUST_FIX.
- Application importing Presentation. Finding: MUST_FIX.

### 1.3 No Layer Skipping

A presentation handler must not call a repository directly — it calls a service, which calls the repository. Finding: MUST_FIX.

### 1.4 Cross-Cutting Concerns

Logging, authentication, metrics, and error handling must be implemented as composable components (middleware, interceptors, decorators), not duplicated ad-hoc across layers. Finding for duplicated cross-cutting logic: SHOULD_FIX.

---

## 2. API Design Principles

### 2.1 RESTful for HTTP APIs

Resources are nouns; actions are HTTP methods. Exception: complex operations may use a verb sub-resource (e.g., `POST /cards/{id}/activate`) with PR justification. Finding for RPC-style endpoints without justification: SHOULD_FIX.

### 2.2 Resource Modeling

Every API resource must correspond to a domain concept, not a database table projection. The API contract is independent of the storage schema. Finding for storage-coupled API design: SHOULD_FIX.

### 2.3 HTTP Method Usage

| Method | Semantics | Idempotent | Safe |
|---|---|---|---|
| GET | Retrieve resource(s) | Yes | Yes |
| POST | Create resource or trigger action | No | No |
| PUT | Full replacement of resource | Yes | No |
| PATCH | Partial update of resource | Yes | No |
| DELETE | Remove resource | Yes | No |

Using GET for mutations or POST for retrieval: MUST_FIX.

### 2.4 Versioning and Backwards Compatibility

URL-based versioning: `/api/v1/`, `/api/v2/`. Breaking changes (removing a field, changing a field type, changing required/optional status, removing an endpoint) require a new version. Additive changes do not. Breaking changes also require: migration guide for consumers, deprecation timeline, and architect approval. Finding for breaking changes without version bump: MUST_FIX. Finding for unintentional breaking changes: MUST_FIX.

---

## 3. Data Architecture

### 3.1 Schema Migrations

All schema changes must be versioned migration scripts — no manual DDL. Migrations must be idempotent and reversible where possible. Finding: MUST_FIX.

### 3.2 No Destructive Single-Step Schema Changes

Dropping columns, changing types, renaming tables, or altering constraints requires a multi-step migration: (1) add new structure, (2) dual-write, (3) backfill, (4) switch reads, (5) remove old. Finding: MUST_FIX.

### 3.3 Data Access Abstraction

All data access goes through a repository or DAO. Business logic never constructs raw queries. Repository interface defined in domain layer; implementation in infrastructure layer. Finding for raw data access in business logic: MUST_FIX.

### 3.4 No Raw SQL in Business Logic

SQL/CQL/query strings must be confined to repository/DAO implementations. Finding for query strings in service or domain layers: MUST_FIX.

---

## 4. Service Boundaries

### 4.1 Service Ownership

Each service has a single owning team controlling its API contract, data schema, deployment, and SLAs. No other team modifies a service's internals without owning team review and approval.

### 4.2 Contracts Between Services

Services communicate through versioned contracts (API schemas, message schemas, event schemas). Both producer and consumer must be updated and tested when contracts change. Finding for undocumented contract changes: MUST_FIX.

### 4.3 No Shared Mutable State

Services must not share databases, caches, or in-memory state. Data requests go through the owning service's API or events. Finding for shared database access between services: MUST_FIX.

### 4.4 Asynchronous Communication

Cross-service non-blocking operations must use async patterns (events, queues, pub/sub). Synchronous chains across more than two services must be justified — they create cascading failure risk. Finding for unjustified synchronous chains: SHOULD_FIX.

---

## 5. Dependency Management

### 5.1 Approval for New Dependencies

Adding an external dependency requires architect approval. PR must include: what it does, why existing deps can't satisfy the need, maintenance status, license compatibility, and security posture. Finding: MUST_FIX.

### 5.2 Maintenance Requirements

Dependencies must be actively maintained. No releases in 18 months with unresolved critical issues = unmaintained; must be replaced or forked. Finding: MUST_FIX.

### 5.3 CVE Policy

- Critical CVE (CVSS >= 9.0): MUST_FIX (Sev0)
- High CVE (CVSS >= 7.0): MUST_FIX (Sev1)
- Medium/low: track and address within normal release cycle.

### 5.4 Standard Library Preference

Prefer standard library over external dependencies for basic functionality. Finding for unnecessary external dependency: SHOULD_FIX.

### 5.5 Lock File

The dependency lock file must be committed. Builds must be reproducible. Finding: MUST_FIX.

---

## 6. Change Impact Classification

Determines required review depth.

| Class | Definition | Required Review |
|---|---|---|
| Trivial | Single file, no behavior change (typo, comment, import reorder) | One reviewer; no architect required |
| Standard | Feature within existing patterns and conventions | `reviewer.standards`, `reviewer.quality`, `reviewer.tests` |
| Significant | New pattern, new external integration, API contract change, modified architectural boundary | All standard reviewers + `architect.principal` |
| Critical | New service, breaking API change, data migration, security model change, infrastructure change | Full suite including `architect.principal`, `reviewer.security`, `security.appsec-analyst`; ADR required |
