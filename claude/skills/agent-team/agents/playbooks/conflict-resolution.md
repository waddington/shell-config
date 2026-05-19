# Conflict Resolution Playbook

All conflicts route through `lead`. No agent resolves conflicts directly with another.

---

## 1. Conflict Types

| Type | Definition | Detection |
|------|-----------|-----------|
| **Review disagreement** | Two reviewers issue contradictory findings on the same change. | Lead detects during review fan-in when findings reference the same code region with contradictory verdicts. |
| **Priority disagreement** | `prioritiser` and Lead disagree on task ordering or priority. | Lead detects when comparing `prioritiser` output to iteration goals. |
| **Architectural disagreement** | `architect.principal` and an implementer disagree on structural approach. | Implementer sends `ESCALATION: reason: CONFLICT` referencing `architect.principal`, or architect issues disputed `CHANGES_REQUESTED`. |
| **Scope disagreement** | `product.pm` and an implementer disagree on what requirements mean or what should be built. | Implementer sends `ESCALATION: reason: AMBIGUITY` or `reason: SCOPE_CREEP`. |
| **Security vs. velocity** | A security reviewer blocks a change; implementer or Lead argues the risk is acceptable. | `ESCALATION: reason: CONFLICT` referencing a security role, or `verdict: BLOCKED` from a security reviewer. |

---

## 2. Resolution Protocol

Every conflict, regardless of type, follows these steps:

**Step 1 — Acknowledge.** Validate the `ESCALATION` message. Send acknowledgment to the escalating agent. Log the conflict (timestamp, parties, task_id, type).

**Step 2 — Gather perspectives.** Send a `QUESTION` to each party: position, supporting evidence, and impact if their position is not adopted. Wait for both `ANSWER` messages. If a party does not respond after two follow-ups, proceed on available information.

**Step 3 — Apply precedence hierarchy.** See Section 3. The first applicable rule determines the outcome.

**Step 4 — Communicate decision.** Send a decision message to both parties containing: the specific action to be taken, rationale (which rule applied and why), follow-up tasks required, and a finality statement. Apply any task modifications immediately.

**Step 5 — Verify compliance.** When the implementer sends `TASK_DONE`, confirm the decision was implemented in substance, not just technically. Passive-aggressive compliance → send back with `CHANGES_REQUESTED` citing the original decision.

---

## 3. Precedence Hierarchy

Apply rules in order. First applicable rule wins. Do not skip.

**Rule 1 — Security wins over velocity (always).** If one position improves security and the other improves speed or convenience, the security position wins. No exceptions. "Acceptable risk" arguments do not override this rule. Burden of proof is on the party claiming the finding is invalid — they must show the attack vector does not exist with specific technical evidence, not opinion.

**Rule 2 — Protocol wins over convenience (always).** If one position follows established protocol (protocol files, standards, playbooks) and the other proposes a shortcut, the protocol-compliant position wins. Standards apply unless Lead determines the standard itself is incorrect (then update the standard via a proper task — do not bypass it).

**Rule 3 — Architect wins on structural decisions.** Structural = module/service boundaries, data model design, integration patterns, layering, dependency direction. NOT structural = variable names within a method, algorithm choice for a bounded computation, internal method organisation within an approved structure.

**Rule 4 — Implementer wins on implementation details.** Within an architect-approved structure: variable and method naming (within conventions), algorithm choice, internal method decomposition, error message wording, log message format, local code organisation.

**Rule 5 — PM wins on product requirements.** `product.pm` has authority on what the product should do. If the implementer claims a requirement is technically infeasible: Lead asks `architect.principal` for a feasibility assessment. If infeasible → revise requirement. If feasible → requirement stands.

**Rule 6 — Lead has final authority on task management.** Priority, assignment, sequencing, scope, scheduling. Lead decides. Not subject to precedence rules.

---

## 4. Tie-Breaking Rules

**4.1 Contradictory MUST_FIX from two reviewers.** Compare evidence quality. Assess risk profile — which position, if ignored, creates higher risk? Structural conflict → consult `architect.principal`. Correctness conflict → the position preventing a bug or data corruption wins. If equally valid, Lead makes a judgment call and documents rationale.

**4.2 Reviewer MUST_FIX vs. implementer disagreement.** The finding stands. Lead may override ONLY if: Lead can document specific evidence (not opinion) that the identified risk does not exist; the justification is recorded; and the finding is NOT a security finding.

**4.3 Disputed security finding.** The security finding stands. The only exception: Lead may downgrade `MUST_FIX` → `SHOULD_FIX` ONLY IF all of: (1) Lead provides written justification that risk is mitigated by existing controls, (2) the security reviewer explicitly consents, (3) the downgrade is documented, and (4) a follow-up task is created. Lead may NEVER dismiss a security finding entirely.

**4.4 Priority disagreement with prioritiser.** Lead has final authority (Rule 6) but must document the reason for overriding. Give significant weight to data-driven reasoning from `prioritiser`.

---

## 5. Human Escalation

Escalate to the human when:
- The precedence hierarchy does not produce a clear resolution.
- The conflict involves a fundamental product direction question only the human can answer.
- Both sides of a security vs. velocity conflict have strong evidence-backed positions.
- The conflict has persisted across 2 resolution attempts without stable outcome.
- The conflict reveals a gap in standards or protocols needing human input.

**Escalation format:**
- Conflict summary (1–2 sentences)
- Party A: role, position, key evidence
- Party B: role, position, key evidence
- Precedence rules considered and why they didn't resolve it
- Lead's recommended resolution
- Specific question or decision needed from human

After human decision: communicate it to both parties, apply task changes, document rationale.

---

## 6. Anti-Patterns

1. **Agents arguing directly** — skipping formal conflict resolution.
2. **Lead deciding without both perspectives** — snap decisions based on one party's view.
3. **Overriding security for velocity** — time pressure does not override security findings.
4. **Re-litigating resolved conflicts** — raising the same conflict without new evidence. Decisions are final for the iteration.
5. **Passive-aggressive compliance** — technically satisfying a decision while undermining its intent.
6. **Conflict avoidance** — silently implementing something different instead of escalating disagreement.
7. **Lead avoiding decisions** — deferring to human instead of applying the precedence hierarchy.
8. **Out-of-order hierarchy** — skipping Rule 1 to apply a later rule because a party made a compelling argument.
9. **Undocumented precedent** — making a decision that effectively changes protocol without flagging it for update.
