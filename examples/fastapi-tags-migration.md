---
feature: Note tags and tag filter
status: draft            # draft | approved | in-progress | done
created: 2026-10-22
planner: feature-planner@1.0.0
---

# Feature: Note tags and tag filter

## 1. Summary

Users can attach tags to their notes and list only the notes that carry a given tag. Tags are private to each user and stored in a normalized `tags` table with a `note_tags` association table, which keeps `GET /notes?tag=` a simple indexed join. Tags are set when a note is created and replaced on an existing note through a new `PUT /notes/{note_id}/tags`. Storing tags as a comma-separated column on `notes` was the alternative; it was rejected because filtering would rely on string matching and per-user tag reuse would be hard to enforce.

## 2. Requirements

- R1: A user can set tags on a new note (`POST /notes`) and replace the full tag set on an existing note.
- R2: Tag names are normalized (trimmed, lowercased), 1–50 characters, unique per note, at most 20 per note.
- R3: `GET /notes?tag=<name>` returns only the caller's notes that have that tag, newest first.
- R4: Tags and tagged notes belong to one user; another user never sees or changes them.
- R5: Existing endpoints keep their behavior; `NoteOut` gains a `tags` field.

## 3. Existing Architecture

- `app/models.py` (confirmed): `User` and `Note` (`owner_id` FK, `title`, `body`, `created_at`); no tag concept exists yet.
- `app/schemas.py` (confirmed): `NoteCreate` (`title`, `body=""`) and `NoteOut` (`from_attributes=True`).
- `app/routers/notes.py` (confirmed): `GET /notes` and `POST /notes` only, both scoped by `owner_id == user.id`. `create_note` calls `Note(owner_id=..., **payload.model_dump())`, so `tags` must be removed from the dump before the model is built.
- `app/auth.py` (confirmed): `current_user` trusts the `X-User-Id` header; the code marks real token auth as a TODO.
- `app/db.py` (confirmed): SQLAlchemy 2.0 `DeclarativeBase` and a `get_db` session dependency.
- `alembic/versions/0001_initial.py` (confirmed): the only revision; creates `users` and `notes`. Revision IDs are short strings (`"0001"`).
- `tests/conftest.py` (confirmed): `db` builds an in-memory SQLite schema with `Base.metadata.create_all` (allowed in tests only) and seeds user 1; `client` overrides `get_db` and sends `X-User-Id: 1`.
- `tests/test_notes.py` (confirmed): one create-and-list test.
- Conventions: one router file per resource in `app/routers/`; Pydantic schemas in `app/schemas.py`; schema changes only through Alembic; plain function routes with `response_model` and `status_code`; tests use the `client` and `db` fixtures.
- Tests run with `pytest` from the project root (`[tool.pytest.ini_options]`, dev extras `pytest>=8`, `httpx>=0.27`).

## 4. Proposed Approach

- **Models:** add `Tag` (`id`, `owner_id` FK to `users`, `name` String(50), unique on `(owner_id, name)`) and a `note_tags` table (`note_id` and `tag_id` FKs with `ondelete="CASCADE"`, composite primary key). `Note.tags` is a many-to-many relationship; `Note.tag_names` is a property returning sorted names for the response.
- **Normalization:** one `normalize_tag()` function in `app/schemas.py`, used by the create and replace schemas and by the `tag` query parameter, so writes and filters match.
- **Schemas:** `NoteCreate.tags: list[str] = []`; new `NoteTagsUpdate(tags: list[str])`; `NoteOut.tags` is read from `tag_names`.
- **Router:** a private `_resolve_tags(db, owner_id, names)` in `app/routers/notes.py` gets or creates the owner's `Tag` rows. `list_notes` takes an optional `tag` query and eager-loads tags with `selectinload` to avoid one query per note. The new `PUT /notes/{note_id}/tags` looks up the note with `owner_id == user.id`.
- **Concurrency:** if two requests create the same tag name at once, the unique constraint raises `IntegrityError`. `_resolve_tags` rolls back and re-reads the row.

**Out of scope:** tag rename or delete, a `GET /tags` listing, multi-tag AND/OR filters, note update or delete endpoints, pagination, real token auth, tag colors or metadata.

## 5. Files to Create or Modify

| File | Status | Change |
| ---- | ------ | ------ |
| `app/models.py` | confirmed | Add `Tag`, `note_tags`, `Note.tags`, and `Note.tag_names` |
| `app/schemas.py` | confirmed | Add `normalize_tag()`, `tags` on `NoteCreate` and `NoteOut`, and `NoteTagsUpdate` |
| `app/routers/notes.py` | confirmed | Store tags on create, filter by `tag` in list, eager-load tags, add `PUT /notes/{note_id}/tags` |
| `alembic/versions/0002_note_tags.py` | proposed | Create `tags` and `note_tags`; `down_revision = "0001"`; downgrade drops both |
| `tests/test_notes.py` | confirmed | Add create-with-tags and unfiltered-list cases |
| `tests/test_tags.py` | proposed | Normalization, filter, isolation, and replace cases |

## 6. Implementation Tasks

- [ ] **T1 — Tag models and migration** · `app/models.py` (confirmed), `alembic/versions/0002_note_tags.py` (proposed) · depends on: none
  - Done when: `Tag` has a unique `(owner_id, name)` constraint; `note_tags` FKs cascade on delete; `Note.tag_names` returns sorted names; `alembic upgrade head` from `0001` creates both tables and `alembic downgrade 0001` drops them.
  - Tests: two notes of one owner share a tag row; a duplicate `(owner_id, name)` raises `IntegrityError`; migration upgrade and downgrade run against a scratch database.
- [ ] **T2 — Tag normalization and schemas** · `app/schemas.py` (confirmed) · depends on: none
  - Done when: `normalize_tag` trims and lowercases; empty, whitespace-only, or over-50-character names fail validation with 422; duplicates collapse keeping first-seen order; more than 20 tags fails with 422; `NoteCreate` defaults `tags` to `[]`; `NoteOut` serializes `tags`.
  - Tests: `"  Work "` becomes `"work"`; `""`, `"   "`, a 51-character name, and 21 distinct tags each return 422; duplicates collapse; a create body without `tags` is accepted.
- [ ] **T3 — Store tags on create and return them** · `app/routers/notes.py` (confirmed) · depends on: T1, T2
  - Done when: `POST /notes` with `tags` returns 201 with normalized tags; an existing owner tag is reused rather than duplicated; `tags` is removed before `Note(...)` is built; `GET /notes` returns each note's `tags` from one eager-loaded query.
  - Tests: create with tags then list shows them; a second note reusing `work` adds no `tags` row; omitting `tags` yields `"tags": []`.
- [ ] **T4 — Filter notes by tag** · `app/routers/notes.py` (confirmed) · depends on: T3
  - Done when: `GET /notes?tag=Work` returns only the caller's notes tagged `work`, newest first; a tag with no matches returns 200 with `[]`; a blank `tag` returns 422; omitting `tag` returns the full list as before.
  - Tests: matching filter; a note of user 2 with the same tag is excluded; unknown tag returns `[]`; blank tag returns 422; unfiltered list unchanged.
- [ ] **T5 — Replace a note's tags** · `app/routers/notes.py` (confirmed) · depends on: T3
  - Done when: `PUT /notes/{note_id}/tags` replaces the full tag set and returns 200 with `NoteOut`; `[]` clears tags; a note owned by another user or a missing note returns 404 and leaves its tags unchanged.
  - Tests: replace then list shows the new set; clear with `[]`; other user's note returns 404 with tags intact; unknown id returns 404.

## 7. Security, Data, and Compatibility

- **Authorization:** every note lookup and the tag filter join on `owner_id == user.id`. Another user's note returns 404, not 403, so existence is not revealed.
- **Inherited weakness:** the placeholder `X-User-Id` auth in `app/auth.py` is unchanged; this feature does not fix it.
- **Input:** tag names are plain text, length-limited, and capped per note. Any UI rendering them must escape output.
- **Migration:** additive only. `0002` creates two tables and backfills nothing; existing notes have no tags. Downgrade drops the two new tables and no data in `notes` changes.
- **Compatibility:** `NoteOut` gains `tags`, which existing clients can ignore. `POST /notes` without `tags` behaves as before.

## 8. Risks, Assumptions, and Open Questions

- **Assumption:** tags are per user, not global; matching is case-insensitive after normalization; limits are 50 characters per tag and 20 tags per note.
- **Assumption:** tags can be set at creation and replaced via `PUT`; no PATCH is added because no note update endpoint exists.
- **Assumption:** the filter takes one tag with exact match; multi-tag filtering is deferred.
- **Risk:** `alembic/env.py` is not in the repo (only `alembic.ini` and `versions/0001_initial.py` were found), so `alembic upgrade` cannot run as-is. **Mitigation:** confirm where the env file lives, or add it as a prerequisite before T1 is verified.
- **Risk:** the database engine is named only as `database_url` in config, and no driver appears in `pyproject.toml`. Tests run on SQLite, so unique-constraint and cascade behavior may differ on the production engine. **Mitigation:** verify T1 against the real engine.
- **Question:** should tags be per user (as planned) or shared across users?
