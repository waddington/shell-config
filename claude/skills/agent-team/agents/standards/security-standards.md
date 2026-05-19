# Security Standards

**Enforced by:** `reviewer.security`, `security.appsec-analyst`
**Scope:** All source code in this repository. No exceptions.

> **TODO:** These standards are a starting point and require significant refinement. A human must review and rewrite them based on actual CK security policies, internal appsec guidelines, compliance requirements, and patterns from CK repos and engineering guidelines. Do not treat these as authoritative without that review.

Any security vulnerability discovered during review: `MUST_FIX`. No exceptions.

---

## Input Validation

- Whitelist validation preferred over blacklist. Define what is allowed, not what is forbidden.
- Every input MUST have type checking, length limits, and format validation at the system boundary.
- SQL queries MUST use parameterized statements. String concatenation for query construction: `MUST_FIX`.
- All HTML output MUST be encoded to prevent XSS. Use framework-provided encoding utilities.
- User input MUST NOT be passed to shell commands. Command injection via `Runtime.exec()` or equivalent: `MUST_FIX`.
- File path inputs MUST be validated against directory traversal (`../`). Resolve canonical paths before use.
- Reject unexpected fields in request bodies. Do not silently accept unknown properties.

---

## Authentication

- Token-based authentication required for all service-to-service and client-to-service communication.
- All tokens MUST have an expiration (`exp` claim). Tokens without expiration: `MUST_FIX`.
- Tokens MUST be stored securely: `httpOnly` cookies for browser clients, secure credential storage for service clients. Tokens in `localStorage`: `MUST_FIX`.
- Passwords MUST be hashed with `bcrypt` or `argon2`. Plaintext password storage: `MUST_FIX`.
- MFA MUST be enforced for administrative operations where applicable.
- Authentication failures MUST NOT reveal whether the username or password was incorrect. Use generic error messages.
- Rate limiting MUST be applied to all authentication endpoints.

---

## Authorization

- Least privilege MUST govern all access grants.
- Authorization MUST be checked on every request. Relying solely on authentication without per-request authorization: `MUST_FIX`.
- Resource-level authorization required: verify THIS user can access THIS specific resource. Collection-level checks are insufficient.
- Administrative actions MUST require an explicit admin role check. Implicit elevation through parameter manipulation: `MUST_FIX`.
- Security by obscurity is not authorization. Unguessable URLs and hidden endpoints do not constitute access control.
- Deny by default. No explicit permission grant → request MUST be rejected.

---

## Data Protection

- PII MUST be encrypted at rest and in transit. TLS 1.2+ required for all network communication.
- Data retention policies MUST be enforced programmatically. Data beyond retention period MUST be purged automatically.
- PII MUST NOT appear in logs, error messages, monitoring dashboards, or alerting payloads. Any PII leakage into observability systems: `MUST_FIX`.
- Sensitive data MUST NOT be included in URL parameters. URLs are logged by proxies, browsers, and CDNs.
- Secrets MUST be managed through a secret management system (e.g., Vault, AWS Secrets Manager). Secrets in code, committed config, or environment variable defaults in source: `MUST_FIX`.
- API responses MUST NOT include more data than the client requires.

---

## Dependency Security

- All new dependencies MUST be scanned for known CVEs before addition.
- Dependency audits MUST run as part of the CI pipeline.
- No dependency with an unpatched critical CVE may remain. Critical CVEs: `MUST_FIX`.
- Abandoned dependencies with known vulnerabilities MUST be replaced.
- Pin dependency versions in production builds. Floating version ranges introduce supply chain risk.
- Verify dependency integrity through checksums or lock files. Unverified artifacts: `SHOULD_FIX`.

---

## OWASP Top 10

| Category | Requirement |
|---|---|
| A01 — Broken Access Control | Enforce authorization at every endpoint. Deny by default. Validate resource ownership. |
| A02 — Cryptographic Failures | Use AES-256, RSA-2048+, SHA-256+. Never implement custom cryptography. Encrypt sensitive data at rest and in transit. |
| A03 — Injection | Parameterize all database queries. Validate all inputs. Encode all outputs in interpreted contexts. |
| A04 — Insecure Design | Threat model new features before implementation. Include security requirements in acceptance criteria. |
| A05 — Security Misconfiguration | Ship secure defaults. Disable unnecessary features and ports. Fail fast on insecure configuration at startup. |
| A06 — Vulnerable Components | Scan dependencies continuously. Remove unused dependencies to reduce attack surface. |
| A07 — Authentication Failures | Rate-limit auth endpoints. Secure password hashing. Session expiration and invalidation. |
| A08 — Software and Data Integrity | Verify dependency integrity via checksums and lock files. Validate CI/CD pipeline integrity. |
| A09 — Security Logging Failures | Log all security-relevant events (auth, authorization, access control). Alert on suspicious patterns. |
| A10 — SSRF | Validate and sanitize all URLs before server-side requests. Allowlist permitted external hosts. Block internal network ranges (`169.254.x.x`, `10.x.x.x`, `127.0.0.1`). |

---

## Prohibited Practices

Each is a `MUST_FIX` if discovered during review.

| Practice | Why Prohibited |
|---|---|
| Secrets in code or committed configuration | Permanently exposed; cannot be fully revoked. |
| Logging PII or credentials | Logs are broadly accessible and often retained long-term. |
| Disabling security controls for convenience | Temporary disablement tends to become permanent. |
| Deprecated algorithms (MD5, SHA-1, DES, RC4) | Known weaknesses; not suitable for security use. |
| Trusting client-side validation as sole defense | Client-side validation is UX convenience; server-side is the security boundary. |
| Hardcoded credentials | Cannot be rotated without a code deployment. |
| SQL string concatenation | Enables injection attacks. |
| `eval()` on user-provided input | Arbitrary code execution via user input. |
| Deserializing untrusted data without validation | Can lead to remote code execution. |
| HTTP instead of HTTPS for sensitive operations | Exposes data to interception and tampering. |
