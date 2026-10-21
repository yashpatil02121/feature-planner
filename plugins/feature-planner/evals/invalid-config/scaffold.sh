#!/usr/bin/env bash
set -euo pipefail
bash "$(dirname "$0")/../_fixtures/todo-api.sh"
echo '{ "planDirectory": "../outside", "autoImplement": true }' > .feature-planner.json
