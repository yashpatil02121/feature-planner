# Architecture

See [plan.md](plan.md), sections 2–5, for the design. This file records behavior verified in Claude Code itself.

## Phase 2 findings

All tests used Claude Code 2.1.306, headless (`claude -p --plugin-dir`), on a small Express fixture project (2026-10-22).

| # | Question | Result |
| - | -------- | ------ |
| 1 | Does `name: fp` also expose a bare `/fp`? | **No.** The session's slash-command list contains only `feature-planner:fp`. Document the namespaced command, plus the opt-in personal-skill shortcut. |
| 2 | Does `disallowed-tools` block `Edit`, `NotebookEdit`, `Bash` while `fp` runs? | **Yes.** Under `--permission-mode acceptEdits`, where `Edit` is normally auto-approved, an `Edit` on `src/store.js` was refused with "Permission to use Edit has been denied". The file was unchanged. The tools stay listed but every call is denied, so the restriction works as a deny rule, not by removing the tool. |
| 3 | Do `Bash(git …:*)` entries in `allowed-tools` survive `Bash` being disallowed? | **No.** `git log --oneline -1` was denied, so the deny rule wins. The git entries were removed from `allowed-tools`, and inspection uses Glob, Grep, and Read only. |
| 4 | Is writing the plan file blocked in plan mode? | **Yes**, for paths inside the project. Claude writes to the plan-mode file (`~/.claude/plans/…`) instead and calls `ExitPlanMode`. The skill now tells Claude to present the plan through `ExitPlanMode`, save it to `plans/` only after approval, and never implement. In headless mode `ExitPlanMode` is unavailable, and the documented fallback (show the plan in the conversation, give the intended path) was followed. **The interactive approval path was verified by hand on 2026-10-26:** approving with auto-accept edits saved only `plans/…md` (`status: draft`) and changed no source files, and rejecting wrote nothing. |

## Phase 3–5 behavior checks

These were run headless on two fixture stacks: Express with `node:test`, and FastAPI with SQLAlchemy, Alembic and pytest, plus a `CLAUDE.md` and a fake `.env` secret. They are now encoded in the eval suite ([testing.md](testing.md)).

| Scenario | Result |
| -------- | ------ |
| Second stack (FastAPI) | Detected the stack, followed `CLAUDE.md` (Alembic `0002` migration with downgrade), and caught that `alembic/env.py` is missing |
| Secrets | `.env` never read, and no secret value appears in the trace or the plan |
| Ambiguous request | Asked three grounded questions and wrote no plan |
| No arguments | Asked what to plan and wrote nothing |
| Invalid config | Named both errors (unknown key, escaping path) and wrote nothing |
| Existing plan | Asked to replace or save a new version, and the existing file was unchanged |
| Custom config | Saved to `docs/plans/`, with no test tasks when `generateTests: false` |

The fixes these checks prompted:

- **Skill files outside the project.** The "stay in this project" rule made Claude skip the skill's own template and checklist. They are now explicitly exempt (`${CLAUDE_SKILL_DIR}`).
- **`.env.example`.** The two rule files disagreed on it. It is now allowed, because it holds placeholders only.

## Eval suite

The first full pass (2026-10-22, 1 run per case, no baseline) scored 9/9 after one grader fix. The fix: the `python-migration` judge saw only part of a 50-message trace, so it failed a plan that was correct. It was replaced with regex checks on the content of the plan's `Write` call. File-focus graders don't accept globs, and plan filenames are date-based. A suite pass costs about $1.60 and takes about 2 minutes with `-j 4`.

## Phase 8 findings

- **A forwarding `/fp` shortcut doesn't work, and is unsafe.** I tested a project-level skill at `.claude/skills/fp/SKILL.md` that tells Claude to invoke `feature-planner:fp`. `/fp` was registered, but the `Skill` call to the plugin skill failed with no detail. Claude then improvised a plan using `Bash`, outside the skill's tool restrictions. Nothing was edited, but the read-only guarantee did not apply. **The shortcut is not documented.** A bare `/fp` stays on the future list, and should only ship if a skill can reliably delegate to another skill.
- **Clean install verified.** Using an isolated `CLAUDE_CONFIG_DIR`, both `claude plugin install feature-planner --marketplace yashpatil02121/feature-planner` and the two-step `marketplace add` + `install feature-planner@feature-planner` installed the plugin from GitHub. `plugin update` and `plugin uninstall` both worked.

## Baseline comparison (v1.0.0 work)

The full suite ran on 2026-10-22: 9 cases, 3 runs each, with and without the plugin (`--ablation with-without`), on Claude Code 2.1.306. It cost $8.06 and took about 8 minutes.

| Case | With plugin | Without | What plain Claude got wrong |
| ---- | ----------- | ------- | --------------------------- |
| read-only-guarantee | 100% | 27% | Edited source files in 2 of 3 runs and implemented the feature instead of stopping at a plan |
| python-migration | 100% | 38% | Never saved a plan, so none of the migration, rollback, ownership, or stack checks could pass |
| rest-endpoint | 100% | 38% | No saved draft plan; the grounded-plan judge failed it in all 3 runs |
| empty-repo | 100% | 0% | No plan file in any run |
| invalid-config | 100% | 50% | Didn't name both config errors |
| ambiguous-request | 100% | 67% | Didn't ask focused questions in 2 of 3 runs |
| custom-config | 100% | 83% | Ignored `planDirectory` once and included tests once |
| empty-arguments | 100% | 100% | — |
| existing-plan | 100% | 100% | — |

- **With the plugin:** 27 of 27 runs passed. Mean delta over the baseline: **+0.44**.
- **How to read the baseline:** it receives the same text, `/feature-planner:fp …`, as an ordinary request. Some graders are specific to the plugin (the saved plan file, the template), so part of the gap is format.
- **The most meaningful differences** are the behavioral ones: plain Claude **edited code when asked to plan**, and ignored the configuration. The two ties are cases where doing nothing also passes.

## Planning efficiency (after 1.0.0)

Changes made (2026-10-26):

- Parallel-batch inspection instructions.
- Search-first reading with a budget of about 15 files.
- The inspection guide and quality checklist folded into `SKILL.md`, so only the two templates are separate files.

| Measure | Before | After |
| ------- | ------ | ----- |
| Skill-file reads per run | 4 | 2 |
| FastAPI fixture: project reads / tool calls (one headless run each) | 16 / 21 | 11 / 15 |
| Round trips (Express / FastAPI) | 4 / 4 | 3 / 4 |
| Eval average cost per run (Opus) | $0.176 (27 runs) | $0.181 (18 runs) |
| Eval average duration per run | 36 s | 35 s |

- **Claude was already batching independent reads**, so on these small fixtures the changes don't make planning faster or cheaper. The differences are within noise.
- **The intended gain is on large repositories**, where search-first and the reading budget stop unbounded reading. The current fixtures don't exercise that, so it is unmeasured.
- **A quality regression surfaced and was fixed.** One `rest-endpoint` plan replaced automated route tests with "verify manually with curl" and moved the tests into an open question; the judge correctly failed it. The skill now requires automated tests for every behavior-changing task, makes any enabling change (such as exporting the app) a task, and lists new test files.
- **Template rule clarified:** test files don't count toward compact's limit of about four files. After both fixes, 18 of 18 eval runs pass.

## Large-repo measurement

**Fixture:** `shop-monorepo.sh` is a TypeScript/Fastify monorepo: 281 files, 13 packages, and a `CLAUDE.md` that says to reuse shared middleware.

- **Noise:** 44 files in `node_modules/` and `dist/`, plus docs.
- **What the feature needs:** the request "Rate limit password reset requests per email address" touches `packages/auth/src/routes/passwordReset.ts` and should reuse `packages/shared/src/middleware/rateLimit.ts`.

**Run:** headless, 3 runs per skill version, on 2026-10-26 with the default model (Opus).

| Measure (average of 3) | v1.0.0 skill | New skill |
| ---------------------- | ------------ | --------- |
| Round trips | 5.0 | 5.3 |
| Tool calls | 18.0 | 18.3 |
| Project files read (of 237) | 8.7 | 10.3 |
| Reads of `node_modules`/`dist` | 0 | 0 |
| Cost per plan | $0.175 | $0.191 |
| Time | 38 s | 46 s |
| Plan length | 44 lines | 47 lines |
| Reused the shared limiter, no duplicate | 3/3 | 3/3 |

- **Both versions already plan well at this scale.** They use Grep to find the right files, read about 4% of the project, skip the noise, and follow `CLAUDE.md`.
- **The new instructions add no measurable efficiency on this fixture.** The differences are small and within run-to-run noise for 3 samples. The search-first rules and reading budget are guardrails rather than a speed-up: they don't bind here, because Claude already stays focused.
- **Remaining limits:**
  - The fixture's generated code is uniform and greps cleanly. Real repos with ambiguous names, or thousands of files, could still behave differently.
  - The `large-repo` eval passes 3/3 in the eval harness (16–17 reads per run). Harness runs cost more (about $0.29) than headless runs, likely because each run starts with a cold cache.

## Other observations

- **Workspace boundary.** One plan-mode run globbed an additional working directory from the user's settings (`D:/search-auditor`). The skill now restricts inspection to the current working directory. The rerun stayed inside the project.
- **Plan quality.** Plans are well grounded: every file reference is real, the conventions are picked up, the tests account for the shared in-memory store, and they cover edge cases and auth risk. The first plan was about 150 lines for a three-file change and listed itself under "Files". After adding proportionality guidance, the plan was 114 lines and no longer listed itself. A single-endpoint plan still came to 105 lines.
- **Plan length (v1.0.0 work).** Guidance alone didn't shorten plans. The cause was structural: the task section took 40–45% of every plan (four labeled lines plus sub-bullets per task), and twelve fixed sections added about 30 lines of headings. Testing Strategy and Definition of Done repeated the tasks.
  - **Fix:** a size-based choice between a compact template (5 sections) and a trimmed full template (8 sections), a one-line task header with "Done when" and "Tests", and an explicit "say each fact once" rule.
  - **Result:** the same three features went from 147, 189, and 162 lines to 48, 89, and 47. The validation codes, test pitfalls, migration rollback, ownership scoping, and the risks found are all still there.
  - **Guarding against regression:** regex graders fail any plan over 90 lines (compact) or 160 lines (full), and check the template choice.
- **Cost.** About $0.01–0.02 per run on the fixture.
- **Testing from inside the Claude desktop app.** Child `claude` processes inherit host variables (`ANTHROPIC_BASE_URL`, `CLAUDE_CODE_SDK_HAS_HOST_AUTH_REFRESH`, `USE_LOCAL_OAUTH`, …) and fail authentication. Clear the `CLAUDE*`, `ANTHROPIC_BASE_URL`, and `USE_*_OAUTH` variables before running headless tests from there.

Manifest validation: `claude plugin validate . --strict` and `claude plugin validate ./plugins/feature-planner --strict` both pass. The only output is a warning that the plugin has no icon, which matters only for a plugin-directory listing.
