# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Inspection works in parallel batches and searches before reading, with a budget of about 15 files, to keep planning bounded on large repositories.
- The inspection guide and quality checklist are folded into `SKILL.md`, so each run makes 2 fewer reads. The `reference/` folder is removed.
- Test files no longer count toward the compact template's limit of about four files.

### Added

- `large-repo` eval: a 281-file TypeScript monorepo fixture checking that the planner finds buried code, reuses existing shared middleware, stays within its read budget, and skips `node_modules` and `dist`.

### Fixed

- Plans could replace automated tests with manual checks, or defer them to open questions. Behavior-changing tasks now always get automated tests, with any enabling change planned as a task and new test files listed.

## [1.0.0] - 2026-10-26

First stable release. In a comparison run with and without the plugin (9 cases × 3 runs), all 27 runs passed with it, scoring a mean +0.44 higher than plain Claude.

### Changed

- Plans are now sized to the feature. A new **compact** template (summary, context, changes, tasks, risks) is used for small changes, and a shorter eight-section **full** template for everything else. Example plans went from 147–189 lines to 47–89 lines with the same substance.
- Tasks use a denser format: one header line with files and dependencies, then "Done when" and "Tests".
- The separate Scope, Testing Strategy, and Definition of Done sections are gone. Their content now lives in the summary or approach, the tasks, and the risks section.
- The README install section now leads with the terminal commands (`claude plugin install …`), and explains that `/plugin …` is typed inside Claude Code.

### Added

- Eval graders for plan length (at most 90 lines for compact, 160 for full) and for template choice.
- Baseline comparison results in `docs/architecture.md`.

## [0.3.0] - 2026-10-22

First public pre-release.

### Added

- `/feature-planner:fp` skill. It inspects the codebase and writes a structured implementation plan to `plans/<date>-<slug>.md` with `status: draft`.
- Read-only planning, enforced with `disallowed-tools` (`Edit`, `NotebookEdit`, `Bash`).
- Optional `.feature-planner.json` with `planDirectory` and `generateTests`. Invalid configuration stops with a clear error and writes no plan.
- Collision handling: an existing plan is never overwritten without asking.
- Plan-mode support: the plan is presented through plan-mode approval and saved only after approval, with nothing implemented.
- Plan template with confirmed, proposed, and TBD file labels, task checkboxes, and a quality checklist.
- Eval suite of 9 cases on Express and FastAPI fixtures, run with `claude plugin eval`.
- CI: `validate.yml` on every push and pull request, and `evals.yml` weekly and on demand.
- Example plans, documentation, contributing guide, and security policy.

[Unreleased]: https://github.com/yashpatil02121/feature-planner/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yashpatil02121/feature-planner/compare/v0.3.0...v1.0.0
[0.3.0]: https://github.com/yashpatil02121/feature-planner/releases/tag/v0.3.0
