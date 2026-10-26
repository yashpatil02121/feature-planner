#!/usr/bin/env bash
# Repository checks run by CI (.github/workflows/validate.yml). Run locally from
# the repository root with: bash scripts/validate.sh
#
# Needs the Claude Code CLI (`claude`) and Node.js (for npx). No API key is
# required: `claude plugin validate` works offline.
set -uo pipefail

cd "$(dirname "$0")/.."
PLUGIN=plugins/feature-planner
CLAUDE=${CLAUDE_BIN:-claude}
failures=0

step() { printf '\n== %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

step "Plugin and marketplace manifests"
"$CLAUDE" plugin validate . --strict || fail "marketplace manifest"
"$CLAUDE" plugin validate "$PLUGIN" --strict || fail "plugin manifest"

step "Required files"
required=(
  README.md
  LICENSE
  CONTRIBUTING.md
  SECURITY.md
  CHANGELOG.md
  docs/plan.md
  docs/architecture.md
  docs/configuration.md
  docs/testing.md
  examples/README.md
  "$PLUGIN/skills/fp/SKILL.md"
  "$PLUGIN/skills/fp/templates/implementation-plan.md"
  "$PLUGIN/skills/fp/templates/plan-compact.md")
for f in "${required[@]}"; do
  [[ -s "$f" ]] && echo "ok  $f" || fail "missing or empty: $f"
done

step "Text files are UTF-8"
# Catches files saved as UTF-16 (common on Windows), which GitHub and the
# plugin validator cannot read.
git ls-files -z -- '*.md' '*.json' '*.jsonc' '*.yaml' '*.yml' '*.sh' | node -e '
  const fs = require("fs");
  const files = fs.readFileSync(0, "utf8").split("\0").filter(Boolean);
  const decoder = new TextDecoder("utf-8", { fatal: true });
  let bad = 0;
  for (const f of files) {
    if (!fs.existsSync(f)) continue;
    const buf = fs.readFileSync(f);
    let problem = null;
    if (buf[0] === 0xff || buf[0] === 0xfe || buf.includes(0)) problem = "UTF-16 or binary content";
    else if (buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) problem = "UTF-8 byte order mark";
    else { try { decoder.decode(buf); } catch { problem = "invalid UTF-8"; } }
    if (problem) { console.log(`FAIL: ${f}: ${problem}`); bad++; }
  }
  console.log(`checked ${files.length} file(s)`);
  process.exit(bad ? 1 : 0);
' || fail "non-UTF-8 text files"

step "Plugin and marketplace versions match"
plugin_version=$(node -p "require('./$PLUGIN/.claude-plugin/plugin.json').version")
market_version=$(node -p "require('./.claude-plugin/marketplace.json').plugins.find(p => p.name === 'feature-planner').version")
if [[ "$plugin_version" == "$market_version" ]]; then
  echo "ok  $plugin_version"
else
  fail "plugin.json $plugin_version != marketplace.json $market_version"
fi
for f in "$PLUGIN/skills/fp/SKILL.md" "$PLUGIN/skills/fp/templates/"*.md; do
  grep -q "feature-planner@$plugin_version" "$f" \
    && echo "ok  $f planner header uses $plugin_version" \
    || fail "$f planner header does not mention feature-planner@$plugin_version"
done

step "Eval cases"
for dir in "$PLUGIN"/evals/*/; do
  name=$(basename "$dir")
  [[ "$name" == _* || "$name" == results ]] && continue
  case_file="$dir/case.yaml"
  [[ -f "$case_file" ]] || { fail "$name: no case.yaml"; continue; }
  scaffold=$(sed -n 's/^ *scaffold_script: *//p' "$case_file")
  if [[ -n "$scaffold" && ! -f "$dir/$scaffold" ]]; then
    fail "$name: scaffold_script $scaffold not found"
  else
    echo "ok  $name"
  fi
done

step "Shell script syntax"
while IFS= read -r -d '' script; do
  bash -n "$script" && echo "ok  $script" || fail "syntax error in $script"
done < <(find scripts "$PLUGIN/evals" -name '*.sh' -print0)

step "Markdown lint"
npx --yes markdownlint-cli2@0.18.1 || fail "markdown lint"

if (( failures > 0 )); then
  printf '\n%d check(s) failed.\n' "$failures"
  exit 1
fi
printf '\nAll checks passed.\n'
