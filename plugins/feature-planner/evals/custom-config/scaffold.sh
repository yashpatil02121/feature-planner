#!/usr/bin/env bash
set -euo pipefail
bash "$(dirname "$0")/../_fixtures/todo-api.sh"
echo '{ "planDirectory": "docs/plans", "generateTests": false }' > .feature-planner.json
