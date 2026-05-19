# Coding Standards

**Enforced by:** `reviewer.standards` (conventions), `reviewer.quality` (design quality)
**Severity model:** Sev0-Sev3. Findings: MUST_FIX, SHOULD_FIX, NITPICK, PRAISE.
**Scope:** All source code in this repository. No exceptions.

> **TODO:** These standards are a starting point and require significant refinement. A human must review and rewrite them based on actual CK coding conventions, internal style guides, language-specific patterns used in CK repos, and any documented engineering guidelines. Do not treat these as authoritative without that review.

---

## 1. General Principles

### 1.1 SOLID Principles

**Single Responsibility (SRP):** A class or module has exactly one reason to change. If two independent reasons to change exist, split it. Finding: SHOULD_FIX. If it crosses domain boundaries: MUST_FIX.

**Open/Closed (OCP):** Extend behavior through composition, inheritance, or configuration — not by modifying existing working code. Adding a new variant should not require editing a `match`/`switch` block in a core module. Finding: SHOULD_FIX.

**Liskov Substitution (LSP):** Subtypes must be substitutable for their base types without altering correctness. Overriding a method must not tighten preconditions or weaken postconditions. Finding: MUST_FIX.

**Interface Segregation (ISP):** No client should depend on methods it does not use. If a class leaves interface methods as no-ops or throws `UnsupportedOperationException`, the interface is too broad. Finding: SHOULD_FIX.

**Dependency Inversion (DIP):** High-level modules depend on abstractions, not concretions. Business logic must not import infrastructure-specific types (HTTP clients, database drivers) directly. Finding: SHOULD_FIX.

### 1.2 DRY — Rule of Three

Do not extract shared code until the same logic appears in three or more places. Two occurrences may be coincidental. Premature abstraction is worse than duplication. Finding for unjustified duplication (3+ occurrences): SHOULD_FIX. Finding for premature extraction of 2 occurrences with different semantics: SHOULD_FIX.

### 1.3 KISS

The simplest solution that meets requirements is correct. Over-engineering is a defect: abstraction layers with exactly one implementation, generic frameworks for one use case, configuration for things that never vary. Finding: SHOULD_FIX.

### 1.4 Explicit Over Implicit

No magic. No hidden state. Implicit conversions, global mutable state, and action-at-a-distance patterns are prohibited. If a function modifies state outside its signature, that must be obvious from its name. Finding: SHOULD_FIX. If it causes bugs or confusion: MUST_FIX.

### 1.5 Fail Fast

Validate inputs at system boundaries immediately. Never pass invalid data deeper hoping something downstream catches it. Never silently ignore failures. Finding for swallowed errors: MUST_FIX.

---

## 2. Naming Conventions

### 2.1 Variables

Descriptive names. No abbreviations except universally understood ones: `id`, `url`, `http`, `io`, `db`, `api`, `config`, `ctx`, `err`, `req`, `res`. Names describe what the variable holds, not its type. Bad: `strName`, `listItems`. Good: `customerName`, `activeOrders`.

### 2.2 Functions and Methods

Verb-noun format describing what the function does. Bad: `processData`, `handleStuff`. Good: `validateCardToken`, `fetchWalletProvisions`. Pure functions returning a computed value may use noun/adjective form: `totalAmount`, `isExpired`.

### 2.3 Classes and Types

Singular nouns in PascalCase. Name describes what the type represents. Good: `Card`, `WalletProvision`, `TokenValidationResult`.

### 2.4 Constants

`UPPER_SNAKE_CASE` for values known at compile time or application startup that never change. Runtime-loaded configuration values use standard variable casing.

### 2.5 Booleans

Variables: prefix with `is`, `has`, `can`, `should`, `was`, `will`. Functions returning boolean: same prefixes or verbs that imply boolean (`exists`, `contains`, `matches`). Bad: `active`, `valid`. Good: `isActive`, `isValid`.

### 2.6 Files

Follow language convention. Never mix conventions within a project.

### 2.7 Single-Letter Variables

Prohibited except: loop indices (`i`, `j`, `k`), lambda parameters when type is obvious from context, mathematical formulas where single letters are the domain convention. Finding: NITPICK for lambdas, SHOULD_FIX otherwise.

---

## 3. Function Design

### 3.1 Single Responsibility

One function does one thing. If the function name contains "and" (e.g., `validateAndSave`), split it. Finding: SHOULD_FIX.

### 3.2 Parameter Count

Maximum four parameters. Beyond four, use an options object, config class, or builder. Finding for >4: SHOULD_FIX. Finding for >6: MUST_FIX.

### 3.3 Function Length

Target: 30 lines or fewer. 30–50 lines acceptable for a single coherent flow. Over 50 lines requires justification in a comment or PR description. Finding for >50 lines without justification: SHOULD_FIX.

### 3.4 Purity and Side Effects

Functions that appear pure must be pure. If a function has side effects, its name must communicate that: `saveOrder`, `sendNotification`, `updateCache`. Finding for hidden side effects: MUST_FIX.

### 3.5 Early Returns

Use guard clauses to avoid deep nesting. Maximum nesting depth: 3 levels. At 4+ levels, refactor via early return, extract method, or inverted condition. Finding for >3 levels: SHOULD_FIX.

---

## 4. Error Handling

### 4.1 Never Swallow Errors

Every error must be handled (with recovery logic), propagated, or logged and re-raised. Empty catch blocks are prohibited. Finding: MUST_FIX.

### 4.2 Typed Errors

Use the language's type system for errors. In Scala, prefer `Either`, `Try`, or custom ADTs over raw exceptions for expected failure cases. Finding for untyped error handling where typed alternatives exist: SHOULD_FIX.

### 4.3 Error Context

Error messages must answer: what failed, what input caused it, and what the caller can do. Bad: `"Error occurred"`. Good: `"Failed to provision card tokenId=abc123: token expired. Refresh and retry."`. Finding: SHOULD_FIX.

### 4.4 Recoverable vs. Unrecoverable

Recoverable errors (retry, fallback) are handled in application code. Unrecoverable errors (corrupt data, misconfiguration) propagate to the top-level handler. Finding for misclassification: SHOULD_FIX.

### 4.5 Logging Errors

ERROR for failures requiring human attention. WARN for recovered issues. Do not log expected business-logic rejections (invalid user input) as ERROR. Finding for incorrect log levels: NITPICK unless it causes alert noise, then SHOULD_FIX.

### 4.6 No Exceptions for Control Flow

Do not use try/catch as a substitute for conditionals. Do not throw for expected outcomes like "not found" or "already exists" — use return types (`Option`, `Either`, result types). Finding: SHOULD_FIX.

---

## 5. Comments

### 5.1 Self-Documenting Code

Code must be readable without comments. Comments explain why, not what.

### 5.2 Required Comments

- **Public API documentation:** every public method, class, and module must have a doc comment (purpose, parameters, return value, thrown exceptions).
- **Complex algorithm rationale:** explain the approach and why alternatives were rejected.
- **Workaround explanations:** document what is being worked around and link to a tracking issue.
- **TODOs:** must include a ticket reference. Format: `TODO(IPE-12345): description`. Bare `TODO` without a ticket: SHOULD_FIX.

### 5.3 Forbidden Comments

- Commented-out code: delete it. Finding: SHOULD_FIX.
- Obvious explanations (`// increment counter` above `counter += 1`). Finding: NITPICK.
- Changelog comments (`// Added 2024-01-15 by John`). Finding: NITPICK.
- Section separators/banners. Finding: NITPICK.

---

## 6. Code Organization

### 6.1 Feature-Based Grouping

Organize by feature/domain, not technical type. Prefer `wallet/WalletService.scala` over `services/WalletService.scala`. Cross-cutting concerns (logging, auth, error handling) may be grouped by type. Finding for new code using type-based organization: SHOULD_FIX.

### 6.2 Import Order

Three groups separated by blank lines, each sorted alphabetically:
1. Standard library imports
2. External dependency imports
3. Internal project imports

No wildcard imports unless the language idiom strongly favors them. Finding: NITPICK.

### 6.3 One Concept Per File

Each file contains one primary type, class, or module. Helper types closely related to the primary type may co-locate. Finding for unrelated classes in one file: SHOULD_FIX.

### 6.4 No Magic Numbers

Numeric and string literals with domain meaning must be extracted to named constants. Exception: 0, 1, -1, empty string, and values obvious from immediate context. Finding: SHOULD_FIX.
