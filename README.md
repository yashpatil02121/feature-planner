# Feature Planner

[![Validate](https://github.com/yashpatil02121/feature-planner/actions/workflows/validate.yml/badge.svg)](https://github.com/yashpatil02121/feature-planner/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

A Claude Code plugin that plans features before you build them. Describe a feature, and Feature Planner reads your codebase, designs an approach that fits your existing conventions, and saves a structured, reviewable implementation plan to `plans/`. It never touches your source code.

```text
/feature-planner:fp Add password reset
```

> **Status:** v1.0.0. See [CHANGELOG.md](CHANGELOG.md) and the [roadmap](docs/plan.md).

## What it does

- **Reads your code first.** It reads project instructions (`CLAUDE.md`, `CONTRIBUTING.md`), dependency manifests, and the code and tests closest to the feature.
- **Grounds every reference.** Each file in the plan is labeled **confirmed** (read), **proposed** (new), or **TBD**. It does not invent paths.
- **Breaks work into ordered tasks.** Each task has dependencies, acceptance criteria, and tests in your project's real test framework.
- **Flags what matters.** Security, migrations and rollback, backward compatibility, risks, assumptions, and open questions.
- **Is read-only by design.** The planning skill cannot use `Edit` or `Bash`; Claude Code enforces this. The only file it writes is the plan.
- **Leaves approval to you.** Plans are saved with `status: draft`. You approve one by changing it to `status: approved`.

### Why not just use plan mode?

Claude Code's plan mode gives you a plan in the conversation. Feature Planner gives you:

- a **consistent format**;
- a **file in your repository** you can review in a PR and share;
- **grounding rules** that separate what was read from what is assumed;
- a **status field** that later tooling can rely on.

The two work together: if you run `/feature-planner:fp` in plan mode, the plan is presented for approval and saved once you approve.

## Requirements

- [Claude Code](https://code.claude.com) 2.1.275 or later (tested with 2.1.306).
- Nothing else: no server, database, or extra API key.

## Installation

Run this once, in your terminal (PowerShell, Command Prompt, bash, or zsh):

```bash
claude plugin install feature-planner --marketplace yashpatil02121/feature-planner
```

If your Claude Code is older than 2.1.275, add the marketplace first:

```bash
claude plugin marketplace add yashpatil02121/feature-planner
claude plugin install feature-planner@feature-planner
```

Start a new Claude Code session afterwards so the plugin loads.

<details>
<summary>Installing from inside Claude Code instead</summary>

Commands that start with `/` are typed at Claude Code's `>` prompt, not in your terminal. If you type `/plugin` in PowerShell or bash, you'll get "command not found". Start Claude Code with `claude`, then type:

```text
/plugin install feature-planner --marketplace yashpatil02121/feature-planner
```

</details>

## Quick start

1. Open your project in Claude Code:

   ```bash
   cd path/to/your-project
   claude
   ```

2. At Claude Code's `>` prompt, describe the feature:

   ```text
   /feature-planner:fp Let users export their notes as Markdown
   ```

3. The planner reads the relevant code. If the request is ambiguous, it asks up to three clarifying questions and waits for your answers.
4. The plan is saved as `plans/2026-10-22-export-notes-markdown.md`, and you get a short summary with the top risks and open questions.
5. Review the plan, edit it if needed, and set `status: approved` when it's ready.

To see what plans look like, browse [`examples/`](examples/).

### Behavior worth knowing

| Situation | What happens |
| --------- | ------------ |
| No feature given | It asks what to plan and writes nothing |
| Vague request ("make it better") | It asks focused questions grounded in your code instead of guessing |
| A plan with the same name exists | It asks whether to replace it or save a new version, and never overwrites silently |
| Session is in plan mode | The plan is shown for approval and saved only after you approve. Nothing is implemented |
| Empty repository | It says so and produces a bootstrap plan with every file labeled proposed |
| Secrets in `.env` files | Never read and never copied into plans |

## Configuration

This step is optional. Create `.feature-planner.json` in your project root:

```json
{
  "planDirectory": "plans",
  "generateTests": true
}
```

| Setting | Default | Meaning |
| ------- | ------- | ------- |
| `planDirectory` | `"plans"` | Where plans are saved. It must stay inside the project |
| `generateTests` | `true` | Whether tasks include test requirements |

An invalid config stops the planner with a clear error. It never silently falls back to defaults. Details are in [docs/configuration.md](docs/configuration.md).

## Troubleshooting

| Problem | Fix |
| ------- | --- |
| `'/plugin' is not recognized` or `command not found` | You typed a Claude Code command in your terminal. Use `claude plugin install …` in the terminal, or start `claude` first and type `/plugin …` at its prompt. |
| `/fp` doesn't work | Plugin skills are namespaced, so the command is `/feature-planner:fp`. Type `/feature-planner` and pick it from the list. |
| "Permission to use Write" prompt | Claude Code asks before writing the plan file. Allow it, or deny it and the plan is shown in the conversation instead. |
| The plan wasn't saved in plan mode | Plan mode blocks writes until you approve. Approve the plan, or leave plan mode and run the command again. |
| "Configuration is invalid" | Fix the key it names in `.feature-planner.json`. See [docs/configuration.md](docs/configuration.md). |
| The plan cites a file you know is wrong | Labels show what was read (confirmed) and what was guessed (proposed). Please [open an issue](https://github.com/yashpatil02121/feature-planner/issues/new/choose) with the plan excerpt. |

## Updating and uninstalling

From your terminal:

```bash
claude plugin update feature-planner@feature-planner
claude plugin uninstall feature-planner@feature-planner
```

Inside Claude Code, the same commands start with `/plugin` instead of `claude plugin`. Plans you have saved stay in your repository.

## Documentation

- [Configuration](docs/configuration.md)
- [Testing and CI](docs/testing.md): validation script, eval suite, workflows
- [Architecture findings](docs/architecture.md): verified Claude Code behavior
- [Project plan and roadmap](docs/plan.md)
- [Security model](SECURITY.md)

## Contributing and license

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). Report security issues privately as described in [SECURITY.md](SECURITY.md).

[MIT](LICENSE) © Yash Sanjay Patil
