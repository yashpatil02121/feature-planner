# Testing

Feature Planner is a prompt-driven skill, so the tests check behavior, not exact output. Two layers:

1. **Validation:** `claude plugin validate --strict` checks the manifests and plugin structure. It is fast, free, and deterministic.
2. **Evals:** `claude plugin eval` runs real planning sessions against fixture projects and scores them with graders.

## Validation

From the repository root:

```bash
claude plugin validate . --strict
claude plugin validate ./plugins/feature-planner --strict
```

## Eval suite

The cases live in `plugins/feature-planner/evals/`. Each case is a `case.yaml` (prompt and graders) plus a `scaffold.sh` that seeds the empty working directory from a shared fixture in `evals/_fixtures/`.

| Case | What it checks |
| ---- | -------------- |
| `rest-endpoint` | A grounded plan for an Express API, saved as `draft`, with no edits and no writes outside `plans/` |
| `python-migration` | Second stack (FastAPI/SQLAlchemy). Follows `CLAUDE.md` (Alembic migration with rollback) and never reads `.env` or copies its secret |
| `ambiguous-request` | A vague request gets clarifying questions, and no plan is written |
| `empty-arguments` | No arguments: asks what to plan and writes nothing |
| `invalid-config` | An unknown key and an escaping `planDirectory` give a clear error. No defaults fallback, no plan |
| `custom-config` | `planDirectory` and `generateTests: false` are honored |
| `existing-plan` | An existing plan with the same name is never overwritten |
| `read-only-guarantee` | Even when asked to implement, the skill makes no edits (with `Edit` granted to the session) |
| `empty-repo` | An empty project gets a bootstrap plan with every file labeled proposed |

### Running

From `plugins/feature-planner/`:

```bash
claude plugin eval . --scaffold --allow-tools Write Edit --trust-plugin
```

- `--scaffold` is required: it runs each case's `scaffold.sh` to create the fixture project. The scripts need Bash (Git Bash on Windows).
- `--allow-tools Write Edit` grants the gated tools. `Write` is needed to save plans. `Edit` is granted on purpose, so that the read-only cases prove the skill itself blocks it.
- Useful options:
  - `--case <name>` runs one case;
  - `--runs 1 --ablation none` gives a cheap smoke pass;
  - `-j 4` runs cases in parallel;
  - `--json <file>` writes machine-readable results.

**Cost.** One run costs about $0.10–0.25 on the default model. The full suite is 9 cases × 3 runs × 2 arms (with-plugin and the no-plugin baseline) ≈ $8–12. Use `--runs 1 --ablation none` while iterating on the skill.

Results are written to `evals/results/` (gitignored).

### Running inside the Claude desktop app

Child `claude` processes inherit the app's session variables and fail authentication. Clear them first:

```bash
env $(env | cut -d= -f1 | grep -E '^(CLAUDE|ANTHROPIC_BASE_URL|USE_LOCAL_OAUTH|USE_STAGING_OAUTH)' | sed 's/^/-u /') claude plugin eval . --scaffold --allow-tools Write Edit --trust-plugin
```

## Not covered by automation

- **Interactive plan-mode approval:** `ExitPlanMode` is unavailable in headless runs. Check it by hand: run `/feature-planner:fp <feature>` in plan mode, approve, and confirm that the plan is saved to `plans/` and nothing is implemented.
- **Bare `/fp` shortcut:** verified absent (see [architecture.md](architecture.md)).
