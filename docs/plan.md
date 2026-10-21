# Feature Planner — V1 Project Plan

Open-source · Local-first · Claude Code native

## 1. Overview and scope

Feature Planner is an open-source Claude Code plugin. A developer describes a feature; the plugin inspects the existing codebase, designs an approach that fits its conventions, breaks the work into ordered tasks with acceptance criteria and tests, and saves the result as a Markdown plan, all before any code is written.

```
/feature-planner:fp Add password reset
```

### V1 success criteria

1. Installation takes two commands (`/plugin marketplace add`, `/plugin install`).
2. No separate service, database, native binary, or extra API key.
3. The planning command works in any project opened in Claude Code.
4. Plans reference real files and existing conventions, and separate confirmed facts from assumptions.
5. Planning is read-only. Apart from writing the plan file, it cannot modify the project, and this is enforced by tool restrictions rather than only by instructions.
6. Every plan is saved with a `draft` status. Nothing implements it in V1.
7. The repository includes documentation, an eval suite, CI validation, and an open-source license.

### Why not just use plan mode?

Claude Code's built-in plan mode produces a plan in the conversation. Feature Planner adds:

- a consistent, reviewable plan format;
- plans saved to the repository, where they can be version-controlled, shared, and reviewed in PRs;
- grounding rules (confirmed vs. proposed files, assumptions, open questions);
- a status field that a later implementation workflow can rely on.

The README should state this in one paragraph.

## 2. Architecture and technology choices

```
Developer:     /feature-planner:fp Add password reset
                 │
Plugin skill:    SKILL.md workflow + $ARGUMENTS
                 │  tools: Read, Glob, Grep, Write, read-only git
Codebase pass:   project instructions, manifests, routes, models, tests
                 │
Plan output:     plans/<date>-<slug>.md  (status: draft)
                 │
Developer:       reviews, edits, sets status: approved
```

| Component        | Choice                                  | Reason                                                      |
| ---------------- | --------------------------------------- | ----------------------------------------------------------- |
| Plugin interface | Claude Code native plugin               | Native skills and slash commands, marketplace distribution  |
| Planning logic   | Markdown skill (`SKILL.md`)             | Runs in the user's existing Claude Code session              |
| Tool safety      | `allowed-tools` + `disallowed-tools`    | Enforces read-only planning instead of only requesting it   |
| Plugin metadata  | JSON manifests                          | Simple and portable                                         |
| Plan output      | Markdown with a status header           | Easy to review and version-control; machine-checkable status |
| Configuration    | Optional JSON, two settings             | No mandatory setup                                          |
| Validation       | `claude plugin validate --strict`       | Official manifest and structure checks                      |
| Quality testing  | `claude plugin eval`                    | Repeatable cases, graders, comparison against no-plugin baseline |
| Native code      | None                                    | No build or distribution overhead                           |

A native helper (for example in Rust, for fast repository indexing) stays a future option. It would not change the `/fp` workflow.

## 3. Command name

Plugin skills are namespaced. A plugin named `feature-planner` with a skill at `skills/fp/` is invoked as:

```
/feature-planner:fp <feature description>
```

A plugin cannot ship a bare `/fp`: plugin `settings.json` honors only `agent` and `subagentStatusLine`.

**V1 decision:** document `/feature-planner:fp` as the command.

- **Verified in Phase 2:** setting `name: fp` does not expose a bare `/fp`. Only `feature-planner:fp` is registered (see [architecture.md](architecture.md)).
- **Opt-in shortcut:** users who want a bare `/fp` can create a personal skill at `~/.claude/skills/fp/SKILL.md` that forwards to the plugin skill. The README gives the exact file contents. The plugin does not install it automatically.

## 4. Repository structure

```
feature-planner/
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── feature-planner/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   └── fp/
│       │       ├── SKILL.md
│       │       ├── templates/
│       │       │   └── implementation-plan.md
│       │       └── reference/
│       │           ├── codebase-inspection.md
│       │           └── plan-quality-checklist.md
│       └── evals/
│           └── <case>/
│               ├── prompt.md
│               └── graders/
├── examples/
│   ├── react-feature.md
│   ├── django-api.md
│   └── database-migration.md
├── docs/
│   ├── plan.md
│   ├── architecture.md
│   ├── configuration.md
│   └── testing.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
│       ├── validate.yml
│       └── evals.yml
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
├── SECURITY.md
└── LICENSE
```

| File or directory                       | Responsibility                                                    |
| --------------------------------------- | ----------------------------------------------------------------- |
| `.claude-plugin/marketplace.json`       | Makes the plugin installable from this repository                 |
| `plugins/feature-planner/.claude-plugin/plugin.json` | Plugin name, version, description, repository, license |
| `skills/fp/SKILL.md`                    | Core workflow, kept under ~500 lines                              |
| `skills/fp/templates/`                  | Plan template, referenced as `${CLAUDE_SKILL_DIR}/templates/...`  |
| `skills/fp/reference/`                  | Detailed checklists the skill reads when needed                   |
| `evals/`                                | `claude plugin eval` cases and graders                            |
| `examples/`                             | Real plans generated against real open-source repositories        |
| `.github/workflows/validate.yml`        | Manifest and structure validation on every PR                     |
| `.github/workflows/evals.yml`           | Eval suite, nightly or on manual dispatch                         |

The implementation skill is not part of V1 (see section 8).

## 5. Skill definition

### Frontmatter

```yaml
---
name: fp
description: Plan a feature before implementing it. Inspects the codebase and writes a structured implementation plan to the plans directory.
argument-hint: <feature description>
allowed-tools: Read, Glob, Grep, Write
disallowed-tools: Edit, NotebookEdit, Bash
---
```

- `allowed-tools` only pre-approves tools; it does not restrict them. The restriction comes from `disallowed-tools`. Phase 2 verified that it denies `Edit` even under `acceptEdits`.
- No shell access. Phase 2 showed that disallowing `Bash` also overrides `Bash(git …:*)` allowances, so inspection uses Read, Glob, and Grep only.
- `Write` stays available for the plan file. The skill instructions restrict it to the plan directory. This is the one remaining instruction-level control, and the docs must say so.
- Inspection is limited to the current working directory, including when the session has additional working directories configured.

### Arguments

- `$ARGUMENTS` holds the feature description.
- If it is empty, the skill asks what to plan and does nothing else.

### Workflow stages

1. **Understand the request.** Identify the goal, user-facing behavior, constraints, and ambiguities. Ask clarifying questions only when the answer materially changes the plan. Otherwise record explicit assumptions.
2. **Inspect the codebase.** Read `CLAUDE.md` and other project instructions, dependency manifests, entry points, routes, models, and nearby tests. Skip generated files, build output, vendored dependencies, lockfiles, and secret files (`.env*`, key files, credential stores).
3. **Design the approach.** Reuse existing conventions, identify affected components, compare alternatives only when there is a real choice, and record trade-offs.
4. **Break down the work.** Produce ordered tasks with IDs, dependencies, files, intent, acceptance criteria, and tests. Each task should be understandable on its own.
5. **Validate completeness.** Map every requirement to a task and an acceptance criterion. Flag unknowns, security implications, migrations, backward compatibility, and missing tests (checklist in `reference/plan-quality-checklist.md`).
6. **Save and report.** Write the plan with `status: draft`, show a short summary and the file path, and stop.

### Plan mode interaction

Users may run `/fp` while Claude Code is in plan mode, where edits are blocked until the plan is approved.

Phase 2 verified that plan mode blocks writes inside the project. The skill therefore:

1. presents the complete plan through plan mode (the plan-mode plan file and `ExitPlanMode`), stating that approval only saves the plan;
2. on approval, writes it to `plans/` with `status: draft` and stops, never implementing;
3. if `ExitPlanMode` is unavailable (headless) or rejected, shows the plan in the conversation with the intended path.

The interactive approval path still needs a manual check. Document this behavior in the README.

## 6. Plan format

Every plan begins with a status header, followed by the template sections.

```markdown
---
feature: Password reset
status: draft            # draft | approved | in-progress | done
created: 2026-10-22
planner: feature-planner@0.1.0
---

# Feature: Password reset

## 1. Summary
## 2. Requirements
## 3. Existing Architecture
## 4. Proposed Approach
## 5. Scope
### In Scope
### Out of Scope
## 6. Files to Create or Modify
## 7. Implementation Tasks
### T1 — <title>
- [ ] Objective
- Files:
- Depends on:
- Acceptance criteria:
- Tests:
## 8. Testing Strategy
## 9. Security and Data Considerations
## 10. Risks and Assumptions
## 11. Open Questions
## 12. Definition of Done
```

Rules:

- Use paths relative to the project root.
- Label every file as **confirmed** (exists and was read), **proposed** (new), or **TBD**.
- Never invent file names for code that was not inspected.
- Include migrations and rollback steps where relevant, and non-functional requirements (performance, accessibility, observability) when applicable.
- Keep the plan proportional to the feature. A change touching a few files fits in about 80 lines. Sections that don't apply collapse to "None", and no detail is repeated across sections.
- Never list the plan file itself under "Files to Create or Modify".
- Task checkboxes and the `status` field let a future implementation workflow track progress without a separate state store.
- Approval is a human action: the developer edits `status: draft` to `status: approved`.

## 7. Configuration

Optional `.feature-planner.json` in the project root:

```json
{
  "planDirectory": "plans",
  "generateTests": true
}
```

| Setting         | Default   | Behavior                                                                |
| --------------- | --------- | ----------------------------------------------------------------------- |
| `planDirectory` | `"plans"` | Relative directory for plans. Must resolve inside the project root.     |
| `generateTests` | `true`    | Whether every task includes test requirements and the plan includes a testing strategy. |

Rules:

1. A missing file means defaults apply.
2. Invalid JSON, unknown keys, wrong types, or an absolute or escaping `planDirectory` (e.g. `../`) produce a clear error, and no plan is written.
3. No setting grants tools or permissions. Claude Code's permission system always applies.

**Deferred to the implementation workflow:** review and auto-implementation settings. When they arrive, use one setting, `afterPlan: "stop" | "implement"` (default `"stop"`), instead of the earlier `developerReview` and `autoImplement` pair. Only three of that pair's four combinations meant anything.

## 8. V1 scope

**V1 (must have):** marketplace and plugin manifests; the `fp` skill with tool restrictions; plan template with status header; two-setting configuration; safe plan naming; eval suite; CI validation; README, license, examples, contributing guide.

**Early follow-up (v0.x after V1):**

- `implement` skill, with `disable-model-invocation: true` so Claude never starts implementation on its own. It reads a plan, refuses unless `status: approved`, implements tasks in dependency order, ticks checkboxes only for tasks whose tests pass, and reports failures accurately.
- `afterPlan` configuration.
- Plan refinement ("update the plan with …").
- More framework-specific examples.

**Future:**

- Verified bare `/fp` with a supported installer.
- Native indexing helper.
- Support for other coding agents.
- Dependency visualization.
- Automated plan-quality scoring beyond evals.

## 9. Phased backlog

Estimates assume one developer and exclude marketplace review delays.

### Phase 1 — Requirements and conventions (1–2 h)

- Confirm the primary user (developers using Claude Code on existing projects), the command, the empty-argument behavior, the output location, and naming.
- Finalize this document as the source of truth.

**Done when:** every behavior in sections 5–7 is unambiguous.

**Status:** done (2026-10-22). Sections 3 and 5–6 updated with the Phase 2 findings.

### Phase 2 — Manifests and skill skeleton (2–3 h)

- Create `marketplace.json` and `plugin.json` with version, description, repository, and license.
- Create `skills/fp/SKILL.md` with frontmatter and a minimal workflow.
- Run `claude plugin validate . --strict`.
- Load locally with `claude --plugin-dir ./plugins/feature-planner`.
- **Verify by hand:**
  - the namespaced command appears;
  - whether `name: fp` also gives a bare `/fp`;
  - whether `disallowed-tools` blocks `Edit` and `Bash`, and how it interacts with the git allowances;
  - whether `Write` is blocked in plan mode.

**Done when:** validation passes, the command runs, and the four findings are recorded in `docs/architecture.md`.

**Status:** done (2026-10-22). The interactive plan-mode approval path is still to be checked by hand.

### Phase 3 — Core planning workflow (5–7 h)

- Write the six stages, the exclusion rules, and the grounding rules.
- Move detailed checklists into `reference/`.
- Iterate against at least two real projects of different stacks.

**Done when:**

- plans reference real files and label confirmed vs. proposed;
- tasks are ordered with clear completion criteria;
- ambiguous requests produce questions or explicit assumptions;
- no project file other than the plan is modified.

**Status:** done (2026-10-22). Verified on Express and FastAPI fixtures. Plan length is still above the roughly 80-line target for small features.

### Phase 4 — Plan template (1–2 h)

- Finalize the template and status header in `skills/fp/templates/implementation-plan.md`.
- Add proportionality guidance.

**Done when:** a developer can act on a plan without the original conversation, and it renders correctly on GitHub.

**Status:** done (2026-10-22).

### Phase 5 — Configuration and file safety (2–3 h)

- Implement config reading and validation (section 7).
- Name plans `<planDirectory>/<YYYY-MM-DD>-<slug>.md`. If that path exists, ask whether to update it or append `-2`, `-3`, ….
- Never overwrite without explicit confirmation.
- Never copy secret values into plans.

**Done when:** missing, invalid, and path-escaping configs behave as specified, and existing plans are never silently replaced.

**Status:** done (2026-10-22). Covered by the `invalid-config`, `custom-config`, and `existing-plan` evals.

### Phase 6 — Eval suite (4–6 h)

Scaffold with `claude plugin eval init`, then create one case per scenario:

| Case                     | Key graders                                                        |
| ------------------------ | ------------------------------------------------------------------ |
| Small UI feature         | model-judge: concise, names affected components; regex: status header |
| New REST endpoint        | model-judge: routes, validation, errors, tests covered             |
| Database migration       | model-judge: migration order, rollback, compatibility              |
| Authentication feature   | model-judge: security and negative cases                           |
| Ambiguous request        | model-judge: asks questions or states assumptions                  |
| Unknown framework        | model-judge: inspected files before naming the stack               |
| Empty repository         | model-judge: states limits, produces a bootstrap plan              |
| Read-only guarantee      | tool_used: no `Edit` or `Bash`; only one file written              |
| Invalid config           | regex: clear error; tool_used: no `Write`                          |
| Existing plan            | no overwrite without confirmation                                  |
| No arguments             | asks what to plan, writes nothing                                  |

- Cases run against small fixture repositories kept inside each case.
- Use semantic graders rather than exact text matches.
- Track the comparison against the no-plugin baseline: if `/fp` does not beat plain Claude, the skill needs work.

**Done when:** the suite runs locally with `claude plugin eval` and its results are recorded in `docs/testing.md`.

**Status:** done (2026-10-22). 9 cases, 9/9 passing at 1 run per case. The no-plugin baseline comparison has not been run yet.

### Phase 7 — CI and repository quality (2–3 h)

- `validate.yml` runs on every push and PR:
  1. install the Claude Code CLI (the only runtime dependency);
  2. run `claude plugin validate . --strict`;
  3. check that the required docs and LICENSE exist;
  4. lint Markdown.
- `evals.yml` runs nightly and on manual dispatch with `claude plugin eval --json --trust-plugin`, using an API key stored as a repository secret, and gates on the exit code. It does not run on every PR, to control cost.

**Done when:** invalid manifests fail PRs, and contributors can reproduce every check locally.

### Phase 8 — Docs, examples, and release (3–4 h)

- README sections:
  1. what it does, and why not just plan mode;
  2. requirements;
  3. installation;
  4. quick start;
  5. optional bare `/fp` shortcut;
  6. configuration;
  7. example plans;
  8. troubleshooting, including the plan-mode behavior;
  9. updating and uninstalling;
  10. contributing and license.
- Generate the three examples against real open-source repositories.
- Test installation from a clean environment via `/plugin marketplace add <owner>/feature-planner` and `/plugin install feature-planner@<marketplace-name>`.
- Write the CHANGELOG and tag.

Release sequence:

1. `v0.1.0`: local prototype (end of Phase 3).
2. `v0.2.0`: template, configuration, and evals.
3. `v0.3.0`: marketplace install validated, docs complete.
4. `v1.0.0`: stable behavior with a passing eval suite.

## 10. Security and reliability requirements

- **Enforced least privilege:** the skill's `disallowed-tools` removes `Edit`, `NotebookEdit`, and general `Bash`.
- **Write scope:** plans are written only inside the validated `planDirectory`. This is instruction-level, documented as such in `SECURITY.md`, and covered by an eval.
- **Secret handling:** never read `.env*` or key files. Never copy credential values into plans.
- **No permission escalation:** configuration never grants tools, and Claude Code permissions always apply.
- **Transparent results:** plans separate confirmed facts from assumptions, and proposed tasks from completed ones.
- **Failure handling:** say clearly when files are inaccessible or the plan is incomplete.
- **Reproducibility:** eval cases, fixtures, and graders live in the repository.

## 11. Timeline

| Phase                          | Hours  |
| ------------------------------ | ------ |
| 1. Requirements                | 1–2    |
| 2. Manifests and skeleton      | 2–3    |
| 3. Core planning workflow      | 5–7    |
| 4. Plan template               | 1–2    |
| 5. Configuration and file safety | 2–3  |
| 6. Eval suite                  | 4–6    |
| 7. CI                          | 2–3    |
| 8. Docs, examples, release     | 3–4    |
| **Total**                      | **20–30** |

That is about 3–4 working days. Most of the uncertainty is in Phases 3 and 6, which means repeatedly testing the skill against real projects.

## 12. Definition of done (V1)

- [ ] `claude plugin validate --strict` passes
- [ ] `/feature-planner:fp <description>` is discoverable and works
- [ ] Empty arguments prompt for a feature and write nothing
- [ ] Plans reference real files and label confirmed, proposed, and TBD
- [ ] Plans include ordered tasks, dependencies, acceptance criteria, and tests
- [ ] Planning cannot edit project files (enforced by `disallowed-tools` and covered by an eval)
- [ ] Plans are saved with `status: draft` and are never silently overwritten
- [ ] Missing, invalid, and path-escaping configuration behave as specified
- [ ] Plan-mode behavior is verified and documented
- [ ] The eval suite passes and beats the no-plugin baseline
- [ ] Marketplace installation works from a clean environment
- [ ] README, LICENSE, SECURITY, CONTRIBUTING, CHANGELOG, and examples are complete
- [ ] CI validation passes

## 13. First development session

1. Create the directory structure and LICENSE.
2. Write `marketplace.json` and `plugin.json`, then run `claude plugin validate --strict`.
3. Write `skills/fp/SKILL.md` with frontmatter, tool restrictions, and the six-stage workflow.
4. Add the plan template under `skills/fp/templates/`.
5. Load with `claude --plugin-dir ./plugins/feature-planner` and record the four Phase 2 findings: bare `/fp`, `disallowed-tools` behavior, git allowances, and plan mode.
6. Run `/feature-planner:fp` on a small feature in a real project, and iterate until the plan is grounded, complete, and actionable.

Add configuration, evals, and CI only after step 6 produces plans you would actually use.
