#!/usr/bin/env bash
set -euo pipefail
bash "$(dirname "$0")/../_fixtures/todo-api.sh"
mkdir -p plans
printf -- "---\nfeature: Mark todo as done and delete todo\nstatus: approved\ncreated: %s\n---\n\n# Feature: Mark todo as done and delete todo\n\nORIGINAL-PLAN-MARKER\n" "$(date +%F)" > "plans/$(date +%F)-todo-done-and-delete.md"
