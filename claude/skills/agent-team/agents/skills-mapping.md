# Skills Inventory and Role Mapping

This document maps available Claude skills (from `.claude/skills/`) to the agent roles that should use them. It also classifies each skill by portability — whether it is generic and reusable in any context, or Credit Karma / Intuit specific.

Skills live at the repository root in `.claude/skills/`. They are not part of the agent governance framework; they are capability tools that agents invoke to complete tasks more effectively.

---

## Portability Classification

| Portability | Meaning |
|-------------|---------|
| **Generic** | Works in any codebase or organisation. No CK dependencies. |
| **Partial** | Core logic is generic but uses CK infrastructure (AI Gateway, CK-hosted git, CK Slack workspace). |
| **CK-specific** | Hardcoded to CK/Intuit systems, URLs, project keys, or team names. Not portable without modification. |

---

## Skill-by-Skill Breakdown

### `imgdiff`
- **Portability:** Generic
- **What it does:** Tile-based image comparison using SSIM scoring, heatmaps, and actionable suggestions. Runs as a Docker container with an HTTP API and browser UI.
- **Relevant roles:** `implementer.frontend`, `qa.test-writer`, `reviewer.tests`
- **Usage context:** Visual regression testing for frontend changes. Template rendering verification. Comparing "before" and "after" screenshots of UI components.

---

### `gdrive`
- **Portability:** Generic
- **What it does:** Searches Google Drive and downloads documents to the local filesystem using Google OAuth.
- **Relevant roles:** `product.pm`, `docs.writer`, `lead`
- **Usage context:** Pulling product specs, PRDs, design docs, or meeting notes from Drive into the working context. `docs.writer` uses it to discover documentation that already exists in Drive before writing new in-repo docs.

---

### `html-to-markdown`
- **Portability:** Generic
- **What it does:** Converts HTML files (especially Google Docs exports) to clean Markdown, preserving tables, images, and formatting.
- **Relevant roles:** `docs.writer`, `product.pm`
- **Usage context:** Converting Google Doc exports to Markdown for in-repo documentation. `docs.writer` uses this as part of the discovery and migration workflow when existing docs live in Google Docs.

---

### `office-to-markdown`
- **Portability:** Generic
- **What it does:** Converts `.docx`, `.xlsx`, `.pptx` files to Markdown/CSV using pandoc, with image extraction.
- **Relevant roles:** `docs.writer`, `product.pm`
- **Usage context:** Same use case as `html-to-markdown` but for Office documents. `docs.writer` uses this when source documentation exists in Word or PowerPoint format.

---

### `pdf-to-markdown`
- **Portability:** Partial (uses CK AI Gateway for Claude API calls)
- **What it does:** Converts PDFs to Markdown via Claude vision API by rendering pages as images.
- **Relevant roles:** `docs.writer`, `product.pm`, `security.threat-modeler`
- **Usage context:** Ingesting PDF specs, architecture diagrams, compliance documents, or vendor documentation into working context. `security.threat-modeler` uses this for reading compliance or audit reports in PDF form.

---

### `video-to-tutorial`
- **Portability:** Partial (uses CK AI Gateway for Claude API calls)
- **What it does:** Converts MP4/MOV recordings to step-by-step Markdown tutorials using FFmpeg frame extraction and Claude vision.
- **Relevant roles:** `docs.writer`
- **Usage context:** When a walkthrough video exists for a feature, `docs.writer` can convert it to a written tutorial rather than authoring from scratch.

---

### `google-auth-token`
- **Portability:** Partial (hosted on CK git; uses generic Google OAuth)
- **What it does:** Obtains and caches a Google OAuth access token for Drive, Docs, Sheets, Slides, and Gmail APIs.
- **Relevant roles:** `lead`, `docs.writer`, `product.pm`
- **Usage context:** Prerequisite for `gdrive` and any skill that calls Google APIs. Usually invoked automatically as a dependency.

---

### `spelunker`
- **Portability:** CK-specific
- **What it does:** Investigates logs, errors, alerts, and metrics from CK Kubernetes pods using `ck` CLI, Splunk, and NewRelic. Traces errors back to source.
- **Relevant roles:** `debugger`, `observability`, `perf.reliability`
- **Usage context:** CK-specific incident investigation and root cause analysis. `debugger` uses it to trace production or test-environment failures. `observability` uses it to audit log and metric coverage. `perf.reliability` uses it for latency and throughput investigation.

---

### `slack`
- **Portability:** CK-specific (hardcoded to `intuit.enterprise.slack.com`)
- **What it does:** Reads, posts, replies to, and searches Slack messages in the Intuit/CK workspace.
- **Relevant roles:** `lead`
- **Usage context:** `lead` is the sole human-facing agent. If communication channels extend to Slack (status updates, blocker alerts, escalations), `lead` uses this skill. No other role communicates externally.

---

### `slack-status-from-meeting`
- **Portability:** CK-specific (hardcoded team mapping, channel names, sprint board)
- **What it does:** Converts meeting transcripts into formatted Slack standup updates and weekly status messages with proper @mentions and project grouping.
- **Relevant roles:** `lead`
- **Usage context:** When the human asks `lead` to post a status update based on current iteration state, `lead` uses this to format the output for the Slack channel.

---

### `jira-ticket-management`
- **Portability:** CK-specific (hardcoded to `jira.creditkarma.com`, CK project keys, CK component IDs)
- **What it does:** Full JIRA lifecycle — create, update, transition, link to epics, upload attachments, sync from epics.
- **Relevant roles:** `lead`, `prioritiser`, `product.pm`
- **Usage context:** `prioritiser` uses it to fetch and update the backlog. `product.pm` uses it to create tickets from requirements. `lead` uses it to track task state against the JIRA board. `debugger` may use it to create bug tickets from diagnostic findings.

---

### `jira-links-formatter`
- **Portability:** CK-specific (hardcoded to `jira.creditkarma.com`)
- **What it does:** Formats JIRA ticket IDs as markdown links and copies to clipboard.
- **Relevant roles:** `lead`, `docs.writer`
- **Usage context:** Light utility. `lead` uses it when including ticket references in status reports. `docs.writer` uses it when linking tickets from documentation.

---

### `tech-debt`
- **Portability:** CK-specific (hardcoded IPE project, Maples component, specific epic ID)
- **What it does:** One-liner to create a tech debt JIRA ticket pre-linked to the Maples tech debt epic.
- **Relevant roles:** `lead`, `implementer.backend`, `implementer.frontend`, `implementer.platform`
- **Usage context:** When an implementer identifies tech debt during implementation but it is out of scope for the current iteration, they send a `TASK_PROPOSAL` to Lead. Lead uses this skill to log the debt ticket quickly before rejecting the proposal as out-of-scope.

---

### `work-summary`
- **Portability:** CK-specific (uses `jira.creditkarma.com` and CK custom JIRA fields)
- **What it does:** Generates a report of PRs and JIRA tickets worked on over a time period, with stats by repo, month, type, and epic.
- **Relevant roles:** `lead`, `prioritiser`
- **Usage context:** End-of-sprint or end-of-iteration reporting. `lead` uses it to produce the iteration completion summary for the human.

---

### `tech-lead-communication`
- **Portability:** Partial (templates are generic; references CK org structure)
- **What it does:** Provides templates and guidance for tech lead communication: weekly status, blocker alerts, decision requests, milestone announcements, and scope changes.
- **Relevant roles:** `lead`
- **Usage context:** When `lead` needs to produce a structured status report, escalation message, or stakeholder communication. The templates map well to the Lead's `STATUS_REPORT` and `ESCALATION` message types.

---

### `template-design-verify`
- **Portability:** CK-specific (Spindle/Fabric, `maes_template-manager`, CK playground)
- **What it does:** Iteratively verifies Spindle/Fabric template designs by running parity tests, generating playground screenshots, and comparing with target designs.
- **Relevant roles:** `implementer.frontend`, `qa.test-writer`, `reviewer.tests`
- **Usage context:** CK template development workflow. `implementer.frontend` uses it during implementation to verify design fidelity. `qa.test-writer` uses it to produce test evidence. `reviewer.tests` uses it to validate visual correctness.

---

### `template-parity-copy-graphql`
- **Portability:** CK-specific (Spindle/Fabric conversion pipeline)
- **What it does:** Runs template parity and reproduces the Fabric Playground GraphQL conversion in script form, printing and copying the payload.
- **Relevant roles:** `implementer.frontend`, `qa.test-writer`
- **Usage context:** CK template development. Used to extract and verify the GraphQL payload produced by Fabric template conversion without manual playground interaction.

---

### `template-shover`
- **Portability:** CK-specific (CK Kubernetes dev segments, specific pod naming, memcache invalidation)
- **What it does:** Pushes `.hbs` template files directly to running Kubernetes pods in dev segments for instant live testing.
- **Relevant roles:** `implementer.frontend`
- **Usage context:** CK template hot-reload workflow. `implementer.frontend` uses this during active template development to test changes without rebuilding and redeploying.

---

## Summary by Role

| Role | Relevant Skills |
|------|----------------|
| `lead` | `slack`, `slack-status-from-meeting`, `jira-ticket-management`, `jira-links-formatter`, `tech-debt`, `work-summary`, `tech-lead-communication`, `google-auth-token`, `gdrive` |
| `prioritiser` | `jira-ticket-management`, `work-summary` |
| `product.pm` | `jira-ticket-management`, `gdrive`, `html-to-markdown`, `office-to-markdown`, `pdf-to-markdown`, `google-auth-token` |
| `architect.principal` | _(none — reads designs and code; no tool-heavy workflows)_ |
| `implementer.backend` | `tech-debt` |
| `implementer.frontend` | `imgdiff`, `tech-debt`, `template-design-verify`, `template-parity-copy-graphql`, `template-shover` |
| `implementer.platform` | `tech-debt` |
| `reviewer.security` | _(none)_ |
| `reviewer.correctness` | _(none)_ |
| `reviewer.tests` | `imgdiff`, `template-design-verify` |
| `reviewer.quality` | _(none)_ |
| `reviewer.standards` | _(none)_ |
| `security.threat-modeler` | `pdf-to-markdown` |
| `security.appsec-analyst` | _(none)_ |
| `qa.test-designer` | _(none — designs strategy from specs; no tool-heavy workflows)_ |
| `qa.test-writer` | `imgdiff`, `template-design-verify`, `template-parity-copy-graphql` |
| `debugger` | `spelunker` |
| `perf.reliability` | `spelunker` |
| `observability` | `spelunker` |
| `docs.writer` | `gdrive`, `html-to-markdown`, `office-to-markdown`, `pdf-to-markdown`, `video-to-tutorial`, `jira-links-formatter`, `google-auth-token` |

---

## Skills Not Mapped to Any Role

| Skill | Reason |
|-------|--------|
| `dist` | Not a skill — packaging directory containing zipped skill distributions. |

---

## CK-Specific Skills: Portability Notes

If this agent framework is used outside of Credit Karma, the following skills require modification or replacement:

| Skill | CK Dependency | To Port |
|-------|--------------|---------|
| `spelunker` | CK `ck` CLI, Splunk at `splunk.ckint.io`, CK Kubernetes namespaces | Replace with org-specific log/metric tooling |
| `slack` | `intuit.enterprise.slack.com` workspace tokens | Update workspace URL and auth method |
| `slack-status-from-meeting` | Hardcoded team mapping, channel names, sprint board ID | Replace `team-mapping.json` and channel references |
| `jira-ticket-management` | `jira.creditkarma.com`, CK project keys, CK component IDs | Update base URL, project keys, component IDs |
| `jira-links-formatter` | `jira.creditkarma.com` | Update base URL |
| `tech-debt` | Hardcoded IPE project, Maples component, specific epic ID | Update project key, component, epic link |
| `work-summary` | `jira.creditkarma.com`, CK custom JIRA field IDs | Update URL and custom field IDs |
| `template-design-verify` | Spindle/Fabric, `maes_template-manager`, CK playground | CK-only, no generic equivalent |
| `template-parity-copy-graphql` | CK Fabric conversion pipeline | CK-only, no generic equivalent |
| `template-shover` | CK Kubernetes dev segments, specific pod pattern | Replace with org-specific pod tooling |
| `pdf-to-markdown` | CK AI Gateway | Update to direct Anthropic API or other gateway |
| `video-to-tutorial` | CK AI Gateway | Update to direct Anthropic API or other gateway |
| `google-auth-token` | Hosted on CK git | Clone and host independently |
| `tech-lead-communication` | References CK org hierarchy | Adjust templates for your org structure |
