# Architecture

See [plan.md](plan.md), sections 2–5, for the design. This file records behavior verified in Claude Code itself.

## Phase 2 findings

All tests used Claude Code 2.1.306, headless (`claude -p --plugin-dir`), on a small Express fixture project (2026-10-22).

| # | Question | Result |
| - | -------- | ------ |
| 1 | Does `name: fp` also expose a bare `/fp`? | **No.** The session's slash-command list contains only `feature-planner:fp`. Document the namespaced command, plus the opt-in personal-skill shortcut. |
| 2 | Does `disallowed-tools` block `Edit`, `NotebookEdit`, `Bash` while `fp` runs? | **Yes.** Under `--permission-mode acceptEdits`, where `Edit` is normally auto-approved, an `Edit` on `src/store.js` was refused with "Permission to use Edit has been denied". The file was unchanged. The tools stay listed but every call is denied, so the restriction works as a deny rule, not by removing the tool. |
| 3 | Do `Bash(git …:*)` entries in `allowed-tools` survive `Bash` being disallowed? | **No.** `git log --oneline -1` was denied, so the deny rule wins. The git entries were removed from `allowed-tools`, and inspection uses Glob, Grep, and Read only. |
| 4 | Is writing the plan file blocked in plan mode? | **Yes**, for paths inside the project. Claude writes to the plan-mode file (`~/.claude/plans/…`) instead and calls `ExitPlanMode`. The skill now tells Claude to present the plan through `ExitPlanMode`, save it to `plans/` only after approval, and never implement. In headless mode `ExitPlanMode` is unavailable, and the documented fallback (show the plan in the conversation, give the intended path) was followed. **The interactive approval path is not yet verified.** |

## Other observations

- **Workspace boundary.** One plan-mode run globbed an additional working directory from the user's settings (`D:/search-auditor`). The skill now restricts inspection to the current working directory. The rerun stayed inside the project.
- **Plan quality.** Plans are well grounded: every file reference is real, the conventions are picked up, the tests account for the shared in-memory store, and they cover edge cases and auth risk. The first plan was about 150 lines for a three-file change and listed itself under "Files". After adding proportionality guidance, the plan was 114 lines and no longer listed itself.
- **Cost.** About $0.01–0.02 per run on the fixture.
- **Testing from inside the Claude desktop app.** Child `claude` processes inherit host variables (`ANTHROPIC_BASE_URL`, `CLAUDE_CODE_SDK_HAS_HOST_AUTH_REFRESH`, `USE_LOCAL_OAUTH`, …) and fail authentication. Clear the `CLAUDE*`, `ANTHROPIC_BASE_URL`, and `USE_*_OAUTH` variables before running headless tests from there.

Manifest validation: `claude plugin validate . --strict` and `claude plugin validate ./plugins/feature-planner --strict` both pass. The only output is a warning that the plugin has no icon, which matters only for a plugin-directory listing.
