# Example plans

These are unedited plans from `/feature-planner:fp` (unreleased skill, after the plan-length work), generated against the fixture projects in [`plugins/feature-planner/evals/_fixtures/`](../plugins/feature-planner/evals/_fixtures/). You can recreate any of them by running the fixture script in an empty directory and then running the same command.

| Example | Template | Project | Command | What it shows |
| ------- | -------- | ------- | ------- | ------------- |
| [express-rest-endpoint.md](express-rest-endpoint.md) | compact (48 lines) | Express + `node:test` todo API (`todo-api.sh`) | `/feature-planner:fp Add the ability to mark a todo as done and delete a todo` | Reuses the existing router, store, and error shape. Concrete status codes. Avoids the shared-state test pitfall |
| [fastapi-tags-migration.md](fastapi-tags-migration.md) | full (89 lines) | FastAPI + SQLAlchemy + Alembic notes service (`notes-service.sh`) | `/feature-planner:fp Let users tag notes and filter their notes by tag` | Follows `CLAUDE.md` (Alembic migration with downgrade), scopes data per owner, flags the missing `alembic/env.py` and the placeholder auth |
| [empty-repo-bootstrap.md](empty-repo-bootstrap.md) | compact (47 lines) | Empty directory | `/feature-planner:fp Build a Python command-line tool that converts CSV files to JSON` | States that no code exists and labels every file as proposed |

The planner picks the **compact** template for small changes (about four files at most, with no migration, auth change, new dependency, or breaking API change). It uses the **full** template for everything else.

Things to look for:

- **Confirmed, proposed, and TBD labels.** Every file the planner did not read is marked as not yet existing.
- **Ordered tasks** with dependencies, acceptance criteria, and tests.
- **Assumptions and open questions** stated explicitly instead of being built silently into tasks.
