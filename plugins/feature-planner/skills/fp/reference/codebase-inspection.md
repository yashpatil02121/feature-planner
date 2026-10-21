# Codebase inspection guide

The goal is an accurate picture of the parts of the project the feature touches, built from files you actually read.

## Order of inspection

1. **Project instructions.** Read `CLAUDE.md` (root and any nested ones near the affected area), `AGENTS.md`, `CONTRIBUTING.md`, and `README.md`. Conventions stated here outrank your defaults.
2. **Stack and tooling.** Read the dependency manifests to learn the language, framework, test runner, and lint and format tools:
   - `package.json`, `pyproject.toml`, `requirements*.txt`, `Cargo.toml`, `go.mod`;
   - `pom.xml`, `build.gradle*`, `Gemfile`, `composer.json`, `*.csproj`.
3. **Layout.** Use Glob to see the directory structure, excluding the "Always skip" directories below. Identify where routes and controllers, models and schemas, UI components, services, migrations, and tests live.
4. **Nearest neighbors.** Find the existing code most similar to the requested feature (Grep for related domain terms, route paths, and model names). Read it. The new feature should look like it.
5. **Tests.** Read at least one existing test near the affected area to learn the test style, fixtures, and naming.

Stay inside the project root (the current working directory) throughout.

## Always skip

- **Dependencies and build output:** `node_modules/`, `vendor/`, `.venv/`, `venv/`, `dist/`, `build/`, `out/`, `target/`, `.next/`, `coverage/`.
- **Lockfiles:** `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `Cargo.lock`, and similar. The manifests are enough.
- **Generated and minified files:** `*.min.js`, `*.map`, files with a "generated, do not edit" header.
- **Binary assets and large data files.**
- **Secrets:** `.env` and `.env.*` (except `.env.example` and `.env.sample`), `*.pem`, `*.key`, `id_rsa*`, `credentials*`, `secrets/`. If config matters, refer to the variable *name* from code or from an `.env.example` file, never a value.

## Labeling what you found

- **confirmed:** you read the file in this run and it exists.
- **proposed:** a new file you are recommending, with a path that follows the project's existing layout.
- **TBD:** the right location depends on an open question.

When you are inferring rather than reading, for example "auth middleware probably lives in `middleware/`", either confirm it by reading the file or record it as an assumption.

## Unknown or unusual stacks

If you do not recognize the framework, say so. Base the plan on the patterns you can see in the code rather than on a framework you guess at.
