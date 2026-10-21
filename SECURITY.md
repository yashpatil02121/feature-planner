# Security

## Reporting a vulnerability

Please report security issues privately through [GitHub's private vulnerability reporting](https://github.com/yashpatil02121/feature-planner/security/advisories/new). Do not open a public issue. Expect an initial response within a week.

Examples of what counts:

- a way to make the planning skill modify project files or run commands;
- a way to make it write outside the configured plan directory;
- a way to make it copy secret values into a plan.

## Security model

Feature Planner runs inside your Claude Code session, with your permissions. It does not add a server, network calls, or credentials of its own.

| Control | How it is enforced |
| ------- | ------------------ |
| No file edits, no shell commands during planning | **Enforced by Claude Code.** The `fp` skill sets `disallowed-tools: Edit, NotebookEdit, Bash`, so those calls are denied while it runs, even in `acceptEdits` mode. Covered by the `read-only-guarantee` eval. |
| Write only the plan file, inside `planDirectory` | **Instruction-level.** The skill can use `Write` (it needs it to save the plan), and its instructions restrict that to the plan directory. Claude Code's permission prompts still apply to every write. Covered by evals, but this is not a hard boundary. |
| Config cannot escape the project | **Instruction-level.** The skill rejects absolute paths and `..` segments in `planDirectory`. |
| No secrets in plans | **Instruction-level.** The skill skips `.env`, key, and credential files, and refers to settings by name only. Covered by the `python-migration` eval, which plants a fake secret. |
| Stays inside the project | **Instruction-level.** The skill only inspects the current working directory, plus its own reference files. |
| No permission escalation | **Enforced by design.** `.feature-planner.json` has no setting that grants tools or permissions. |

The plugin does not change Claude Code's own permission system. If you need hard guarantees for the instruction-level controls, add permission rules in your Claude Code settings, for example denying `Write` outside `plans/` and denying `Read` on `.env*`.

## Supported versions

Only the latest release receives fixes.
