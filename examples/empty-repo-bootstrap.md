---
feature: CSV to JSON command-line tool
status: draft            # draft | approved | in-progress | done
created: 2026-10-22
planner: feature-planner@0.3.0
---

# Feature: CSV to JSON command-line tool

## 1. Summary

Build a small Python CLI, `csv2json`, that reads a CSV file (or stdin) and writes its rows as a JSON array of objects keyed by the header row, to stdout or to a file. It uses only the standard library and a `src/` package layout with a console entry point. The project directory is empty, so this plan bootstraps the project.

## 2. Requirements

- R1: Convert a CSV with a header row into a JSON array with one object per data row.
- R2: Read from a file path or stdin (`-`); write to stdout or to `-o/--output`.
- R3: Options `-d/--delimiter` (single character, default `,`) and `-e/--encoding` (default `utf-8-sig`).
- R4: Handle quoted fields, embedded delimiters and newlines, CRLF line endings, and a UTF-8 BOM.
- R5: Reject malformed input (ragged rows, empty or duplicate header names, empty file, bad encoding, missing file) with a one-line stderr message and a non-zero exit code. No tracebacks for these.
- R6: Pretty-print by default (indent 2); `--compact` writes a single line.

## 3. Existing Architecture

The project directory contains no files at all: no source, manifests, `CLAUDE.md`, `AGENTS.md`, `README.md`, tests, or `.feature-planner.json` (defaults apply: `planDirectory: "plans"`, `generateTests: true`). There are no confirmed conventions to follow. The stack comes from the request (Python), and the plan uses the standard `src/` layout.

## 4. Proposed Approach

Three small layers:

- `converter.py`: pure functions. `read_rows(text_stream, delimiter)` returns a list of `dict[str, str]`; `write_json(rows, out_stream, compact)` writes the JSON.
- `cli.py`: `main(argv=None) -> int` handles argparse, opens files, and maps errors to exit codes.
- `__main__.py`: `python -m csv2json` calls `cli.main`.

Alternatives considered:

- **JSON Lines output** streams in constant memory, but "convert to JSON" usually means a JSON document. Recommendation: JSON array by default. JSON Lines is an open question.
- **click or typer** add dependencies for about four options. Recommendation: argparse.

Conventions to follow in every task:

- Open input with `newline=""` so `csv` handles embedded newlines correctly on Windows.
- Write output as UTF-8 with `\n` line endings, not the platform default. Write stdout as UTF-8 bytes so non-ASCII text works on Windows consoles.
- Parse the whole input before opening the output file, so `-o` pointing at the input cannot truncate it before it is read.

## 5. Scope

### In Scope

- CSV-to-JSON-array conversion, options R2–R6, error handling, tests, and a README usage section.

### Out of Scope

- Type inference (numbers, booleans, null). All values are strings.
- JSON Lines output, other input formats, headerless CSV, batch conversion of several files, and streaming for very large files.

## 6. Files to Create or Modify

| File | Status | Change |
| ---- | ------ | ------ |
| `pyproject.toml` | proposed | Package metadata, `requires-python >= 3.10`, no runtime dependencies, `csv2json = "csv2json.cli:main"` script |
| `src/csv2json/__init__.py` | proposed | `__version__` |
| `src/csv2json/__main__.py` | proposed | Delegates to `cli.main` |
| `src/csv2json/converter.py` | proposed | `read_rows`, `write_json` |
| `src/csv2json/cli.py` | proposed | Argument parsing, I/O, exit codes |
| `tests/test_converter.py` | proposed | Converter unit tests |
| `tests/test_cli.py` | proposed | CLI tests that call `main(argv)` and subprocess smoke test of `python -m csv2json` |
| `README.md` | proposed | Install and usage |

## 7. Implementation Tasks

### T1 — Scaffold the package

- [ ] **Objective:** Create the project skeleton so the package imports and the console script is declared.
- **Files:** `pyproject.toml`, `src/csv2json/__init__.py`, `src/csv2json/__main__.py` (all proposed)
- **Depends on:** None
- **Acceptance criteria:**
  - `pyproject.toml` declares `requires-python >= 3.10`, no runtime dependencies, and the `csv2json` script entry.
  - `import csv2json` succeeds and exposes `__version__`.
- **Tests:** None on their own; the import and `--help` smoke tests live in T3.

### T2 — Conversion core

- [ ] **Objective:** Implement `read_rows` and `write_json` in `converter.py`.
- **Files:** `src/csv2json/converter.py` (proposed), `tests/test_converter.py` (proposed)
- **Depends on:** T1
- **Acceptance criteria:**
  - The first CSV row is the header; each data row becomes a dict keyed by header.
  - A header-only input returns `[]`. A zero-length input raises `ValueError` ("no header row").
  - A row whose field count differs from the header raises `ValueError` naming the line number.
  - Empty or duplicate header names raise `ValueError`.
  - `write_json` emits valid JSON with `ensure_ascii=False`, indent 2 unless `compact` is set, and a trailing newline.
- **Tests:**
  - Quoted fields with commas, quotes, and embedded newlines.
  - CRLF input; a custom delimiter (`;`, tab).
  - Header-only, empty, ragged-row, duplicate-header, and empty-header-name cases.
  - Non-ASCII values round-trip through `write_json`.

### T3 — Command-line interface

- [ ] **Objective:** Implement `main(argv=None) -> int` in `cli.py`, covering R2–R6 and the exit-code contract.
- **Files:** `src/csv2json/cli.py` (proposed), `tests/test_cli.py` (proposed)
- **Depends on:** T2
- **Acceptance criteria:**
  - Arguments: positional `input` (path or `-`, default `-`); `-o/--output`; `-d/--delimiter`; `-e/--encoding` (default `utf-8-sig`, which also strips a BOM); `--compact`.
  - Exit 0 on success. Exit 1 for runtime errors (missing file, decode error, malformed CSV, write failure). Exit 2 for argparse errors, including a delimiter that is not exactly one character.
  - Errors print `csv2json: error: <message>` to stderr. No traceback.
  - Output is opened only after input is fully parsed.
- **Tests:**
  - Exit codes for each error class.
  - Stdin input; `-o` file output; stdout output.
  - `--compact` output is one line.
  - `python -m csv2json --help` exits 0 (subprocess smoke test).

### T4 — README usage

- [ ] **Objective:** Document installation, usage, options, and exit codes.
- **Files:** `README.md` (proposed)
- **Depends on:** T3
- **Acceptance criteria:**
  - Install command and one input/output example.
  - Options and exit codes match the flags and behavior in T3.
  - States that all values are strings.
- **Tests:** None (documentation).

## 8. Testing Strategy

- **Runner:** stdlib `unittest`, with no dev dependency. Command: `python -m unittest discover -s tests -v`. This is an assumption; see Open Questions.
- **Coverage:** unit tests for the converter (T2) and CLI behavior with `main(argv)` plus one subprocess smoke test (T3). Edge cases are listed in those tasks.
- **Not covered:** performance on very large files; no benchmark is in scope.

## 9. Security and Data Considerations

- Input is untrusted. Only the `csv` and `json` standard-library modules are used. No `eval`, `pickle`, or network access.
- Malformed input is rejected before any output is written, so a failed run never leaves a partial file.
- Writing to an existing `-o` path overwrites it without prompting, like shell `>` redirection. This is an assumption; see Open Questions.
- No secrets or configuration values are involved.

## 10. Risks and Assumptions

- **Assumption:** Python 3.10+ is the floor, since the repo pins no version.
- **Assumption:** The header row is required, and all values are strings.
- **Assumption:** Ragged rows are errors, not padded or truncated.
- **Assumption:** The default output is a JSON array of objects, not JSON Lines.
- **Risk:** The whole file is held in memory, so very large files may fail. **Mitigation:** JSON Lines output (open question 2) would stream.
- **Risk:** Non-ASCII output on Windows consoles could garble. **Mitigation:** stdout is written as UTF-8 bytes (Section 4).

## 11. Open Questions

1. Should an opt-in flag infer types (numbers, booleans, empty to null)? Assumed no.
2. Is JSON Lines output wanted for large files? Assumed no.
3. Use stdlib `unittest` (assumed) or `pytest`?
4. Adopt `ruff` and `mypy` for lint and type checks? If yes, add them as dev extras in T1. Assumed no.
5. Should `-o` refuse to overwrite an existing file without a `--force` flag? Assumed no.

## 12. Definition of Done

- [ ] All tasks T1–T4 complete and their acceptance criteria met
- [ ] `python -m unittest discover -s tests -v` passes
- [ ] `csv2json` runs from the console script and `python -m csv2json` on a sample CSV
- [ ] Lint and type checks pass, if adopted (open question 4)
- [ ] README matches actual `--help` output
