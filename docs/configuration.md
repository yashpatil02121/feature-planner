# Configuration

Configuration is optional. Without a config file, plans go to `plans/` and include tests.

To customize, create `.feature-planner.json` in your project root (the directory you run Claude Code from):

```json
{
  "planDirectory": "plans",
  "generateTests": true
}
```

## Settings

| Setting | Type | Default | Behavior |
| ------- | ---- | ------- | -------- |
| `planDirectory` | string | `"plans"` | Where plans are saved, relative to the project root. It must stay inside the project: no absolute paths, drive letters, or `..` segments. |
| `generateTests` | boolean | `true` | When `true`, every task that changes behavior lists its tests, and the plan names the project's test command. When `false`, test tasks are left out. |

## Validation

The planner checks the file before doing anything else. If the file is not valid JSON, has an unknown key, has a value of the wrong type, or has a `planDirectory` that escapes the project, it:

- reports exactly which key is wrong and why;
- writes **no** plan;
- does **not** fall back to defaults.

For example, `{ "planDirectory": "../outside", "autoImplement": true }` is rejected for two reasons: `autoImplement` is not a supported key, and `../outside` leaves the project.

No setting grants tools or permissions. Claude Code's permission system always applies.

## Plan files

Plans are named `<planDirectory>/<YYYY-MM-DD>-<slug>.md`, for example `plans/2026-10-22-password-reset.md`.

If that file already exists, the planner asks whether to replace it or save a new version (`-2`, `-3`, …). It never overwrites without asking.

Every plan starts with a header:

```yaml
---
feature: Password reset
status: draft            # draft | approved | in-progress | done
created: 2026-10-22
planner: feature-planner@0.3.0
---
```

Plans are always saved as `draft`. To approve one, change the status to `approved`. Approval is a deliberate human step, and future tools such as an implementation skill will rely on it.

## Planned settings

Implementation support is planned, along with an `afterPlan: "stop" | "implement"` setting (default `"stop"`). See [plan.md](plan.md), section 8.
