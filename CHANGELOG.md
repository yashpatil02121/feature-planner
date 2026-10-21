# Changelog

All notable changes to this project are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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

[Unreleased]: https://github.com/yashpatil02121/feature-planner/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/yashpatil02121/feature-planner/releases/tag/v0.3.0
