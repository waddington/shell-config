# Security Policy Playbook

Authoritative reference for `reviewer.security`, `security.threat-modeler`, `security.appsec-analyst`, and Lead. Every procedure is binding.

---

## 1. Security Review Triggers

Lead MUST assign `reviewer.security` when any trigger matches. If uncertain → assign. False positives are acceptable; false negatives are not.

| # | Trigger | Additional Reviewer |
|---|---------|-------------------|
| 1 | New API endpoint | `security.appsec-analyst` if endpoint accepts user input |
| 2 | Authentication changes | `security.appsec-analyst` (always) |
| 3 | Authorization changes | `security.appsec-analyst` (always) |
| 4 | New external dependency | `security.appsec-analyst` for vulnerability assessment |
| 5 | Dependency version change | `security.appsec-analyst` if dependency handles security (crypto, auth, parsing) |
| 6 | Configuration changes | — |
| 7 | Data model changes (PII) | `security.appsec-analyst` (always for PII) |
| 8 | New external integration | `security.threat-modeler` for threat modeling |
| 9 | Cryptographic operations | `security.appsec-analyst` (always) |
| 10 | Session management | — |
| 11 | File upload/download | — |
| 12 | Logging changes (in sensitive areas) | — |
| 13 | Error handling changes | — |
| 14 | Database query changes (with user input) | — |
| 15 | Serialization/deserialization from untrusted sources | — |

---

## 2. Threat Modeling

**Required for:** new features with new user-facing functionality or data flows; new external integrations; architectural changes to system/trust boundaries; changes to auth/authz model (not just implementation tweaks).

**Not required for:** bug fixes that don't change the security model; refactoring without external interface changes; configuration changes within existing security boundaries; dependency updates (handled by `security.appsec-analyst`).

**Process:**
1. Lead assigns threat modeling task to `security.threat-modeler` with feature description, acceptance criteria, architectural context, and data flow.
2. `security.threat-modeler` produces a threat model using **STRIDE** (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) containing:
   - System description: what is built, data flows, trust boundaries.
   - STRIDE analysis per component and data flow.
   - Threat register: each threat with ID, STRIDE category, description, likelihood, impact, risk rating, proposed mitigation, and mitigation owner.
   - Residual risks: unmitigatable threats with accepted risk level.
3. `reviewer.security` reviews for completeness (all STRIDE categories and data flows covered). `security.appsec-analyst` reviews for accuracy (threat ratings and mitigation effectiveness).
4. Lead creates implementation tasks for each mitigation. Mitigations become acceptance criteria for the implementation task.
5. Implementation task CANNOT be approved until all `MUST_FIX`-severity mitigations are implemented.

---

## 3. Security Review Gates

| Gate | Applies To | Required | Blocks |
|------|-----------|---------|--------|
| 1 — Security review | All trigger-matching changes | `reviewer.security` APPROVED | Any CHANGES_REQUESTED or BLOCKED from `reviewer.security` blocks the task regardless of other approvals |
| 2 — Dependency CVE review | All dependency add/update changes | `security.appsec-analyst` confirms no critical/high CVEs in used code paths | Blocked until CVE mitigated (patched version or proof code path unreachable) |
| 3 — New endpoint threat model | All new API endpoints | Completed, reviewed threat model must exist | Implementation cannot reach APPROVED without it |
| 4 — Auth change review | All auth/authz logic changes | BOTH `reviewer.security` AND `security.appsec-analyst` approve independently | Minimum Sev1 attention; Lead must actively monitor |

**Gate override** — Security gates cannot be overridden except during a Sev0 production incident. Requirements: Lead documents the bypass with full justification; follow-up retroactive review task created for the current iteration; human operator notified; issues found in retroactive review → immediate rollback or hotfix task.

---

## 4. Incident Response

### 4.1 Sev0 — Immediate Risk to Production

**Trigger conditions:** active exploitation detected; credentials exposed in committed state; PII accessible to unauthorized parties; authentication bypass; SQL injection or RCE in production code.

**Response:**
1. Detecting security role broadcasts Sev0 alert to ALL agents (broadcast exception, `index.md §4.2`).
2. All agents immediately pause current work.
3. Lead confirms severity, identifies affected components, determines containment.
4. Lead immediately notifies human operator.
5. Lead assigns containment: block the PR if in pending state; authorize rollback or hotfix if committed; initiate credential rotation if credentials exposed (human may need to act).
6. Lead assigns fix to appropriate implementer at P0 priority.
7. `reviewer.security` reviews the fix.
8. After fix verified and deployed: Lead sends `SYSTEM` to all agents to resume normal operations.
9. Create follow-up post-incident review task.

### 4.2 Sev1 — Significant but Not Immediate Risk

**Trigger conditions:** vulnerability in code under development (not yet in production); weak cryptographic algorithm; missing authz check on non-critical endpoint; known CVE in dependency not yet in production.

**Response:**
1. Any agent sends `ESCALATION: reason: SECURITY` to Lead. No broadcast.
2. Lead evaluates and assigns fix at P1 priority (above all P2/P3 work).
3. `reviewer.security` reviews via standard review process.
4. Lead includes in next scheduled human update (immediate notification not required unless human requested it).

### 4.3 Security Finding in Code Review

Security findings from `reviewer.security` are always `MUST_FIX` unless the reviewer explicitly classifies otherwise. Verdict is `CHANGES_REQUESTED`. Implementer addresses → `reviewer.security` re-reviews. If disputed → conflict resolution per `conflict-resolution.md §4.3` (finding stands unless Lead downgrades with security reviewer consent).

---

## 5. Prohibited Practices

| Practice | Severity | Correct Alternative |
|---------|----------|-------------------|
| **Secrets in code** — API keys, tokens, passwords, private keys in source, config, tests, or comments | In committed code: Sev0 (credential rotation required). In pending PR: `MUST_FIX`. | Environment variables or secrets management. Reference by name, not value. |
| **Logging PII** — names, emails, phones, addresses, gov IDs, passwords, tokens at any log level | `MUST_FIX`. In production: Sev1. | Log opaque IDs (user_id, request_id). Mask if PII necessary: `j***@example.com`. |
| **Disabling security controls** — CSRF protection, TLS validation, permissive CORS on sensitive endpoints, "allow all" auth in non-test code | `MUST_FIX`. In production: Sev1. | Enable controls; configure CORS allowlists. |
| **Deprecated crypto** — MD5/SHA-1 for security, DES/3DES/RC4, RSA < 2048-bit | `MUST_FIX` | SHA-256/SHA-3 for hashing; AES-256 for encryption; RSA-2048+ or ECDSA; bcrypt/scrypt/argon2 for passwords. |
| **Client-side-only validation** | `MUST_FIX` | Validate all input server-side. Client-side may supplement but never replace. |
| **Hardcoded credentials** (even in tests, unless clearly annotated fake) | `MUST_FIX`. If real credential: Sev0. | Use env vars or secrets management. Annotate fakes: `// TEST-ONLY: not a real credential`. |
| **SQL string concatenation** with user input | `MUST_FIX` | Parameterized queries, prepared statements, ORM query builders. |
| **Eval of user input** — `eval()`, `Runtime.exec()`, template injection | `MUST_FIX` (enables RCE) | Never evaluate user-provided input as code. |
| **Open redirects** — redirecting to user-provided URL without allowlist validation | `SHOULD_FIX` (or `MUST_FIX` if from authenticated page) | Validate redirect URLs against an allowlist of known domains. |
| **Insecure deserialization** from untrusted sources without validation | `MUST_FIX` | Validate before deserializing. Avoid formats that support arbitrary object construction. |

---

## 6. Security Review Checklist

**Input validation:**
- [ ] All user-provided input validated server-side
- [ ] Allowlists (not denylists) used where possible
- [ ] Input length limits enforced
- [ ] Special characters properly handled
- [ ] File upload types and sizes restricted

**Authentication:**
- [ ] Auth checks present on all protected endpoints
- [ ] Failed login attempts rate-limited
- [ ] Session tokens use cryptographically secure randomness
- [ ] Session tokens invalidated on logout

**Authorization:**
- [ ] Authz checks verify permission for the specific resource, not just auth status
- [ ] Horizontal privilege escalation prevented (User A cannot access User B's resources)
- [ ] Vertical privilege escalation prevented (user cannot access admin functions)

**Data protection:**
- [ ] PII not logged
- [ ] Sensitive data encrypted at rest and in transit
- [ ] Error messages do not expose internal system details
- [ ] API responses do not include more data than necessary

**Dependency security:**
- [ ] New dependencies have no known critical/high CVEs
- [ ] Dependencies are from reputable, actively maintained sources

---

## 7. Escalation

| Finding | Escalation | Response Time |
|---------|-----------|--------------|
| Sev0 (active exploit, credential exposure) | Broadcast to ALL agents; Lead notifies human immediately | Immediate |
| Sev1 (vulnerability in development, weak crypto, missing authz) | `ESCALATION` to Lead; P1 fix assigned | Before next milestone window |
| `MUST_FIX` in review | Standard `CHANGES_REQUESTED` | Before task approval |
| `SHOULD_FIX` in review | Advisory | Before next iteration |
| Dependency CVE (critical) | `ESCALATION` to Lead; immediate update | Before next merge |
| Dependency CVE (low/medium) | `TASK_PROPOSAL` for scheduled update | Next iteration |

---

## 8. Anti-Patterns

1. **Security as afterthought** — embed security from task creation (threat modeling) through implementation and review.
2. **Security theater** — checkbox reviews without genuine scrutiny. Zero findings on a security-sensitive change should be rare and scrutinised.
3. **Overriding security for deadlines** — security wins over velocity. Always. See `conflict-resolution.md §3 Rule 1`.
4. **Trusting internal callers** — internal service-to-service calls can be compromised or misconfigured. Validate.
5. **Security through obscurity** — assume attackers have full knowledge of the system. Controls must hold regardless.
6. **One-and-done security** — re-evaluate when requirements change, dependencies update, or new threats emerge.
7. **Ignoring low-severity CVEs** — accumulating unpatched low-severity vulnerabilities creates cumulative risk.
8. **Real credentials in test environments** — use dedicated test credentials only.
9. **Cargo-cult security** — each control must have a documented threat it mitigates.
