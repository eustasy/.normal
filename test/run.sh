#!/bin/sh
# Test harness for eustasy/.Normal.
#
# Builds throwaway repositories, runs install.sh into them, and asserts what
# landed. Optionally runs actionlint over deployed caller workflows and zizmor
# over both actions and callers when those binaries are on PATH; CI always has
# them, so CI always runs the full set.
#
# Usage: sh test/run.sh
set -eu

ROOT=$(pwd)
WORK=$(mktemp -d)
FAILURES=0
CHECKS=0

cleanup() {
  # Failure messages name logs inside $WORK, so it has to outlive a failing run.
  if [ "$FAILURES" -eq 0 ]; then
    rm -rf "$WORK"
  else
    printf '\nfixtures kept for inspection: %s\n' "$WORK"
  fi
}
trap cleanup EXIT

pass() {
  CHECKS=$((CHECKS + 1))
  printf '  ok   %s\n' "$1"
}
fail() {
  CHECKS=$((CHECKS + 1))
  FAILURES=$((FAILURES + 1))
  printf '  FAIL %s\n' "$1"
}

assert_file_exists() {
  if [ -e "$1" ]; then pass "$2"; else fail "$2 (missing: $1)"; fi
}

assert_file_missing() {
  if [ -e "$1" ]; then fail "$2 (unexpectedly present: $1)"; else pass "$2"; fi
}

assert_file_contains() {
  if [ -e "$1" ] && grep -qF -- "$2" "$1"; then
    pass "$3"
  else
    fail "$3 (not found in $1: $2)"
  fi
}

# install_into <dir> <branch>: build a fixture repo on <branch>, seeded with one
# file per language .Normal lints, then run install.sh inside it.
install_into() {
  dir="$WORK/$1"
  branch="$2"
  mkdir -p "$dir"
  cp "$ROOT"/empty/test.* "$dir/" 2>/dev/null || true
  cp "$ROOT"/empty/.env.example "$dir/" 2>/dev/null || true
  printf '{\n  "name": "fixture"\n}\n' >"$dir/package.json"
  printf '{\n  "name": "eustasy/fixture"\n}\n' >"$dir/composer.json"
  printf '[project]\nname = "fixture"\n' >"$dir/pyproject.toml"
  (
    cd "$dir"
    git init -q -b "$branch" .
    git config user.email test@example.com
    git config user.name Test
    git add -A
    git commit -qm fixture
    cp -R "$ROOT" .normal
    rm -rf .normal/.git
    cp .normal/install.sh install.sh
    if ! sh install.sh >install.log 2>&1; then
      printf 'install.sh failed in %s\n' "$dir" >&2
      sed 's/^/    /' install.log >&2
      exit 1
    fi
  )
  printf '%s\n' "$dir"
}

printf '\n== scenario: default branch main ==\n'
MAIN=$(install_into main main)
for wf in security css env html js json md php python sh sql \
  test-js test-php test-python type-js type-python xml yaml; do
  assert_file_exists "$MAIN/.github/workflows/$wf.yml" "installs $wf.yml"
done
assert_file_contains "$MAIN/.github/workflows/security.yml" "branches: [main]" \
  "security.yml targets main"
assert_file_exists "$MAIN/.qlty/qlty.toml" "installs qlty.toml"
assert_file_exists "$MAIN/.github/dependabot.yml" "installs dependabot.yml"
assert_file_exists "$MAIN/.github/zizmor.yml" "installs zizmor.yml"
assert_file_contains "$MAIN/.github/zizmor.yml" "eustasy/*: ref-pin" \
  "zizmor.yml exempts the eustasy namespace"

printf '\n== scenario: default branch cf-pages ==\n'
CF=$(install_into cf cf-pages)
assert_file_contains "$CF/.github/workflows/security.yml" "branches: [cf-pages]" \
  "security.yml targets cf-pages"
assert_file_missing "$CF/.github/workflows/security.yml.tmp" "leaves no .tmp files"

printf '\n== lint: caller workflows (actionlint) ==\n'
if command -v actionlint >/dev/null 2>&1; then
  if (cd "$MAIN" && actionlint -no-color -oneline .github/workflows/*.yml); then
    pass "actionlint clean on deployed callers"
  else
    fail "actionlint reported findings on deployed callers"
  fi
else
  printf '  skip actionlint (not on PATH)\n'
fi

printf '\n== lint: actions and callers (zizmor) ==\n'
if command -v zizmor >/dev/null 2>&1; then
  if (cd "$MAIN" && zizmor --no-progress --offline .github/workflows/ >zizmor.log 2>&1); then
    pass "zizmor clean on deployed callers"
  else
    fail "zizmor reported findings on deployed callers (see $MAIN/zizmor.log)"
  fi
else
  printf '  skip zizmor (not on PATH)\n'
fi

printf '\n%s checks, %s failures\n' "$CHECKS" "$FAILURES"
[ "$FAILURES" -eq 0 ]
