# Example plans

These are unedited plans from `/feature-planner:fp` (v0.3.0 skill), generated against the fixture projects in [`plugins/feature-planner/evals/_fixtures/`](../plugins/feature-planner/evals/_fixtures/). You can recreate any of them by running the fixture script in an empty directory and then running the same command.

| Example | Project | Command | What it shows |
| ------- | ------- | ------- | ------------- |
| [express-rest-endpoint.md](express-rest-endpoint.md) | Express + `node:test` todo API (`todo-api.sh`) | `/feature-planner:fp Add the ability to mark a todo as done and delete a todo` | Reuses the existing router, store, and error shape. Strict id validation. Handles the shared-state test pitfall |
| [fastapi-tags-migration.md](fastapi-tags-migration.md) | FastAPI + SQLAlchemy + Alembic notes service (`notes-service.sh`) | `/feature-planner:fp Let users tag notes and filter their notes by tag` | Follows `CLAUDE.md` (Alembic migration with downgrade), scopes data per owner, flags the placeholder auth |
| [empty-repo-bootstrap.md](empty-repo-bootstrap.md) | Empty directory | `/feature-planner:fp Build a Python command-line tool that converts CSV files to JSON` | States that no code exists and labels every file as proposed |

Things to look for:

- **Confirmed, proposed, and TBD labels.** Every file the planner did not read is marked as not yet existing.
- **Ordered tasks** with dependencies, acceptance criteria, and tests.
- **Assumptions and open questions** stated explicitly instead of being built silently into tasks.

These plans are longer than the roughly 80-line target for small features. Tightening that is ongoing work.
