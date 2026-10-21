---
feature: CSV to JSON command-line tool
status: draft            # draft | approved | in-progress | done
created: 2026-10-22
planner: feature-planner@0.3.0
---

# Feature: CSV to JSON command-line tool

## Summary

Add a small Python command-line tool, `csv2json`, that reads a CSV file with a header row and writes a JSON array of objects, one per data row. It uses only the standard library (`csv`, `json`, `argparse`) so it has no runtime dependencies. The conversion core is a plain function that takes streams, so tests run without touching the filesystem, and the CLI is a thin wrapper around it. The project is empty, so this is a minimal bootstrap of a single-module Python package.

## Context

- Repository is empty: no code, manifests, docs, or tests exist (checked for `*`, `**/*.py`, `CLAUDE.md`, `README.md`, `pyproject.toml`). Nothing is confirmed, so every file below is proposed.
- Conventions: none established yet. Use standard Python layout, `snake_case`, type hints, and `CsvError` for user-facing input errors.
- Tests run with `python -m unittest` (stdlib, no test dependency).

## Changes

| File | Status | Change |
| ---- | ------ | ------ |
| `csv_to_json.py` | proposed | `convert()` core, `CsvError`, and `main()` CLI entry point |
| `pyproject.toml` | proposed | Package metadata, Python 3.9+, `csv2json` console script |
| `tests/test_csv_to_json.py` | proposed | `unittest` cases for conversion and CLI behavior |
| `README.md` | proposed | Install and usage, with a short example |

## Tasks

- [ ] **T1 — Conversion core** · `csv_to_json.py` (proposed), `tests/test_csv_to_json.py` (proposed) · depends on: none
  - Done when: `convert(in_stream, delimiter=",")` returns a list of dicts keyed by the header row, all values as strings; a UTF-8 BOM is stripped; header-only or empty input returns `[]`; a row whose length differs from the header raises `CsvError` with its line number; duplicate or blank header names raise `CsvError`.
  - Tests: happy path; header-only; empty input; BOM; quoted commas and embedded newlines; custom delimiter; ragged row; duplicate header; blank header.
- [ ] **T2 — Command-line interface** · `csv_to_json.py` (proposed), `pyproject.toml` (proposed), `tests/test_csv_to_json.py` (proposed) · depends on: T1
  - Done when: `csv2json input.csv` writes JSON to stdout; `-o/--output PATH` writes to a file; `-d/--delimiter` sets the separator; `--indent N` (default 2) sets pretty-printing; `input` may be `-` for stdin; a missing input file exits 2 with a one-line message on stderr; a `CsvError` exits 1 with the message, and no output file is created or truncated; `pip install .` provides the `csv2json` command.
  - Tests: `main(argv)` with stdout capture for default and `-d`; `-o` writes the file; `-` reads stdin; missing file gives exit 2; malformed row gives exit 1 and leaves an existing output file unchanged.
- [ ] **T3 — Documentation** · `README.md` (proposed) · depends on: T2
  - Done when: README covers install (`pip install .`), usage with each option, one example input and its output, and the behavior for empty input and errors.
  - Tests: none. Manual check: install into a fresh venv and run the README example.

## Risks and open questions

- **Assumption:** Values stay strings. Numeric and boolean type inference is out of scope; add it later as an opt-in flag.
- **Assumption:** Output is one JSON array. A JSON Lines option (`--jsonl`) is out of scope.
- **Assumption:** Malformed rows are an error, not padded or skipped, so data is never silently dropped.
- **Assumption:** Encoding is UTF-8 only. Other encodings are out of scope.
- **Question:** Is Python 3.9+ acceptable as the minimum version, and is `unittest` acceptable instead of `pytest`?
