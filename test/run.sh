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

# qlty caches its linters outside PATH; prefer a real PATH binary, then the cache.
find_tool() {
  if command -v "$1" >/dev/null 2>&1; then
    command -v "$1"
    return 0
  fi
  # Lexical, not semver: this would take 1.9 over 1.10. Good enough, because the
  # cache normally holds one version and CI puts pinned binaries on PATH first.
  find "${QLTY_CACHE:-$HOME/.qlty}/cache/tools/$1" -type f -name "$1" -perm -u+x 2>/dev/null |
    sort |
    tail -1
}

# install_into <dir> <branch>: build a fixture repo on <branch>, seeded with one
# file per language .Normal lints, then run install.sh inside it.
install_into() {
  dir="$WORK/$1"
  branch="$2"
  mkdir -p "$dir"
  if [ "${3:-seeded}" = bare ]; then
    printf '# fixture\n' >"$dir/README.md"
  else
    cp "$ROOT"/empty/test.* "$dir/" 2>/dev/null || true
    cp "$ROOT"/empty/.env.example "$dir/" 2>/dev/null || true
    printf '{\n  "name": "fixture"\n}\n' >"$dir/package.json"
    printf '{\n  "name": "eustasy/fixture"\n}\n' >"$dir/composer.json"
    printf '[project]\nname = "fixture"\n' >"$dir/pyproject.toml"
  fi
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

if cmp -s "$ROOT/.github/zizmor.yml" "$ROOT/configs/.github/zizmor.yml"; then
  pass ".github/zizmor.yml matches the shipped configs copy"
else
  fail ".github/zizmor.yml has drifted from configs/.github/zizmor.yml"
fi

printf '\n== scenario: default branch main ==\n'
MAIN=$(install_into main main)
for wf in security actions css env html js json md php python sh sql \
  test-js test-php test-python type-js type-python xml yaml; do
  assert_file_exists "$MAIN/.github/workflows/$wf.yml" "installs $wf.yml"
done
assert_file_contains "$MAIN/.github/workflows/security.yml" "branches: [main]" \
  "security.yml targets main"
for wf in security actions css env html js json md php python sh sql xml yaml; do
  assert_file_contains "$MAIN/.github/workflows/$wf.yml" \
    "uses: eustasy/.normal/$wf@v5" "$wf.yml calls the $wf action"
done
assert_file_contains "$MAIN/.github/workflows/test-php.yml" \
  "uses: eustasy/.normal/php/setup@v5" "test-php.yml calls php/setup"
assert_file_contains "$MAIN/.github/workflows/test-php.yml" \
  "uses: eustasy/.normal/php/test@v5" "test-php.yml calls php/test"
assert_file_contains "$MAIN/.github/workflows/type-js.yml" \
  "uses: eustasy/.normal/js/setup@v5" "type-js.yml calls js/setup"
assert_file_contains "$MAIN/.github/workflows/type-js.yml" \
  "run: npx tsc --noEmit" "type-js.yml runs tsc directly"
assert_file_exists "$MAIN/.qlty/qlty.toml" "installs qlty.toml"
assert_file_exists "$MAIN/.github/dependabot.yml" "installs dependabot.yml"
assert_file_exists "$MAIN/.github/zizmor.yml" "installs zizmor.yml"
assert_file_contains "$MAIN/.github/zizmor.yml" "eustasy/*: ref-pin" \
  "zizmor.yml exempts the eustasy namespace"
assert_file_exists "$MAIN/.github/actionlint.yaml" "installs actionlint.yaml"
assert_file_contains "$MAIN/.github/actionlint.yaml" ".github/workflows/test-*.yml" \
  "actionlint.yaml scopes the if-cond ignore to test-* workflows"

printf '\n== scenario: default branch cf-pages ==\n'
CF=$(install_into cf cf-pages)
assert_file_contains "$CF/.github/workflows/security.yml" "branches: [cf-pages]" \
  "security.yml targets cf-pages"
assert_file_contains "$CF/.github/workflows/actions.yml" "branches: [cf-pages]" \
  "actions.yml targets cf-pages"
assert_file_missing "$CF/.github/workflows/security.yml.tmp" "leaves no .tmp files"

printf '\n== scenario: bare repository ==\n'
BARE=$(install_into bare main bare)
# Security and actions are unconditional; README.md is the only thing
# copy_workflow can match.
assert_file_exists "$BARE/.github/workflows/security.yml" "installs security.yml anyway"
assert_file_exists "$BARE/.github/workflows/actions.yml" "installs actions.yml anyway"
assert_file_exists "$BARE/.github/workflows/md.yml" "installs md.yml for README.md"
for wf in css env html js json php python sh sql xml yaml \
  test-js test-php test-python type-js type-python; do
  assert_file_missing "$BARE/.github/workflows/$wf.yml" "skips $wf.yml with 0 files"
done

# Upgrades need a .normal clone with history: install.sh rebuilds what the
# previous version installed from that version's tag. FAKE is a git repository
# holding this tree twice — tagged 0.9test with a few differences an upgrade has
# to carry across, then this tree as it is — so upgrades are tested offline.
FAKE="$WORK/fake-normal"
mkdir -p "$FAKE"
(cd "$ROOT" && tar --exclude=./.git -cf - .) | (cd "$FAKE" && tar -xf -)
(
  cd "$FAKE"
  git init -q -b main .
  git config user.email test@example.com
  git config user.name Test
  git add -A
  git commit -qm current
  grep -rl 'eustasy/.Normal 5.0' configs install.sh |
    while IFS= read -r f; do
      sed 's/eustasy\/\.Normal 5\.0/eustasy\/.Normal 0.9test/' "$f" >"$f.tmp" && mv "$f.tmp" "$f"
    done
  sed "s/upload: \${{ matrix.php-version == '8.5' }}/upload: \${{ matrix.php-version == '8.6' }}/" \
    configs/.github/workflows/test-php.yml >t.tmp && mv t.tmp configs/.github/workflows/test-php.yml
  sed 's/interval: "monthly"/interval: "weekly"/' install.sh >t.tmp && mv t.tmp install.sh
  git commit -qam old
  git tag 0.9test
  git checkout -q HEAD~1 -- .
  git commit -qm current-again
)

# fixture <name> [ref]: a seeded repo with .Normal at <ref> (default 0.9test)
# installed and committed. Prints the directory.
fixture() {
  dir="$WORK/$1"
  mkdir -p "$dir"
  cp "$ROOT"/empty/test.* "$dir/" 2>/dev/null || true
  printf '{\n  "name": "eustasy/fixture"\n}\n' >"$dir/composer.json"
  (
    cd "$dir"
    git init -q -b main .
    git config user.email test@example.com
    git config user.name Test
    git clone -q "$FAKE" .normal
    git -C .normal checkout -q "${2:-0.9test}"
    printf '.normal/\n*.log\n' >.git/info/exclude
    sh .normal/install.sh >install.log 2>&1
    git add -A
    git commit -qm installed
  )
  printf '%s\n' "$dir"
}

# upgrade <dir>: move .normal to this tree and install again. Prints the exit code.
upgrade() {
  (
    cd "$1"
    git -C .normal checkout -q main
    rc=0
    sh .normal/install.sh >upgrade.log 2>&1 || rc=$?
    printf '%s\n' "$rc"
  )
}

assert_no_markers() {
  if grep -rlq '^<<<<<<< ' "$1/.github" "$1/.qlty" "$1/.vscode" "$1/.editorconfig" 2>/dev/null; then
    fail "$2"
  else
    pass "$2"
  fi
}

printf '\n== upgrade: keeps the project'"'"'s changes ==\n'
UP=$(fixture upgrade)
(
  cd "$UP"
  sed -e '/# Remove the .if: false. below to activate this workflow./d' -e '/^    if: false$/d' \
    -e 's/^      # Insert project-specific steps here.*$/      - name: Seed fixtures\n        run: .\/seed.sh/' \
    .github/workflows/test-php.yml >t.tmp && mv t.tmp .github/workflows/test-php.yml
  printf '\n[[exclude]]\nplugins = ["phpstan"]\nfile_patterns = ["tests/**"]\n' >>.qlty/qlty.toml
  printf '# A project note.\n' >>.github/dependabot.yml
  git rm -q .github/workflows/test-js.yml
  git commit -qam customised
)
rc=$(upgrade "$UP")
if [ "$rc" = 0 ]; then pass "upgrade exits 0"; else fail "upgrade exits 0 (got $rc, see $UP/upgrade.log)"; fi
assert_no_markers "$UP" "upgrade leaves no conflict markers"
if cmp -s "$UP/.github/workflows/security.yml" "$ROOT/configs/.github/workflows/security.yml"; then
  pass "an unchanged workflow updates to this version"
else
  fail "an unchanged workflow updates to this version"
fi
if grep -q 'if: false' "$UP/.github/workflows/test-php.yml"; then
  fail "an activated test-* workflow stays active"
else
  pass "an activated test-* workflow stays active"
fi
assert_file_contains "$UP/.github/workflows/test-php.yml" "run: ./seed.sh" \
  "a project's own step is kept"
assert_file_contains "$UP/.github/workflows/test-php.yml" "matrix.php-version == '8.5'" \
  "the same file still takes this version's changes"
assert_file_contains "$UP/.github/workflows/test-php.yml" "# eustasy/.Normal 5.0" \
  "the header moves to this version"
assert_file_contains "$UP/.qlty/qlty.toml" 'plugins = ["phpstan"]' "qlty.toml keeps a project exclude"
assert_file_contains "$UP/.github/dependabot.yml" "# A project note." "dependabot.yml keeps a project line"
assert_file_contains "$UP/.github/dependabot.yml" 'interval: "monthly"' \
  "dependabot.yml takes this version's generator change"
assert_file_missing "$UP/.github/workflows/test-js.yml" "a deleted workflow stays deleted"

printf '\n== upgrade: both sides changed a line ==\n'
CON=$(fixture conflict)
(
  cd "$CON"
  sed "s/matrix.php-version == '8.6'/matrix.php-version == '8.4'/" \
    .github/workflows/test-php.yml >t.tmp && mv t.tmp .github/workflows/test-php.yml
  git commit -qam customised
)
rc=$(upgrade "$CON")
if [ "$rc" != 0 ]; then pass "a conflict exits non-zero"; else fail "a conflict exits non-zero"; fi
assert_file_contains "$CON/.github/workflows/test-php.yml" "<<<<<<< .github/workflows/test-php.yml (this project)" \
  "the conflicting file carries markers"
assert_file_contains "$CON/upgrade.log" ".github/workflows/test-php.yml" "the conflict is reported"
if cmp -s "$CON/.github/workflows/security.yml" "$ROOT/configs/.github/workflows/security.yml"; then
  pass "other files still update"
else
  fail "other files still update"
fi

printf '\n== upgrade: file types gone from the project ==\n'
GONE=$(fixture gone)
(
  cd "$GONE"
  printf '\n# A project note.\n' >>.github/workflows/sh.yml
  git rm -q test.sql test.sh
  git commit -qam customised
)
rc=$(upgrade "$GONE")
if [ "$rc" = 0 ]; then pass "upgrade exits 0"; else fail "upgrade exits 0 (got $rc, see $GONE/upgrade.log)"; fi
assert_file_missing "$GONE/.github/workflows/sql.yml" "an unchanged workflow for a gone type is removed"
assert_file_exists "$GONE/.github/workflows/sh.yml" "a changed workflow for a gone type is kept"
assert_file_contains "$GONE/upgrade.log" ".github/workflows/sh.yml (changed in this project" \
  "keeping it is reported"

printf '\n== upgrade: same version again ==\n'
SAME=$(fixture same main)
(
  cd "$SAME"
  printf '# A project note.\n' >>.editorconfig
  git commit -qam customised
)
rc=$(upgrade "$SAME")
if [ "$rc" = 0 ] && [ -z "$(cd "$SAME" && git status --porcelain)" ]; then
  pass "re-running the installed version changes nothing"
else
  fail "re-running the installed version changes nothing (see $SAME/upgrade.log)"
fi

printf '\n== upgrade: no tag for the installed version ==\n'
NOTAG=$(fixture notag)
(
  cd "$NOTAG"
  printf '# A project note.\n' >>.editorconfig
  git commit -qam customised
  git -C .normal checkout -q main
  rm -rf .normal/.git
)
rc=$( (cd "$NOTAG" && sh .normal/install.sh >upgrade.log 2>&1) && echo 0 || echo 1)
if [ "$rc" != 0 ]; then pass "a missing tag exits non-zero"; else fail "a missing tag exits non-zero"; fi
if [ -z "$(cd "$NOTAG" && git status --porcelain)" ]; then
  pass "a missing tag changes nothing"
else
  fail "a missing tag changes nothing"
fi
assert_file_contains "$NOTAG/upgrade.log" "NORMAL_PREVIOUS_VERSION" "the fixes are explained"

printf '\n== upgrade: NORMAL_OVERWRITE=1 ==\n'
OVER=$(fixture overwrite)
(
  cd "$OVER"
  printf '# A project note.\n' >>.editorconfig
  git commit -qam customised
  git -C .normal checkout -q main
  NORMAL_OVERWRITE=1 sh .normal/install.sh >upgrade.log 2>&1
)
if cmp -s "$OVER/.editorconfig" "$ROOT/configs/.editorconfig"; then
  pass "NORMAL_OVERWRITE=1 overwrites as before"
else
  fail "NORMAL_OVERWRITE=1 overwrites as before"
fi

printf '\n== lint: caller workflows (actionlint) ==\n'
actionlint_bin=$(find_tool actionlint)
if [ -n "$actionlint_bin" ]; then
  if (cd "$MAIN" && "$actionlint_bin" -no-color -oneline .github/workflows/*.yml); then
    pass "actionlint clean on deployed callers"
  else
    fail "actionlint reported findings on deployed callers"
  fi
else
  printf '  skip actionlint (not found)\n'
fi

printf '\n== lint: actions and callers (zizmor) ==\n'
zizmor_bin=$(find_tool zizmor)
if [ -n "$zizmor_bin" ]; then
  if (cd "$MAIN" && "$zizmor_bin" --no-progress --offline .github/workflows/ >zizmor.log 2>&1); then
    pass "zizmor clean on deployed callers"
  else
    fail "zizmor reported findings on deployed callers (see $MAIN/zizmor.log)"
  fi
else
  printf '  skip zizmor (not found)\n'
fi

printf '\n== actions: zizmor ==\n'
zizmor_bin=$(find_tool zizmor)
if [ -n "$zizmor_bin" ]; then
  # Actions live at <name>/action.yml and <lang>/<verb>/action.yml, so depth 3.
  action_files=$(find "$ROOT" -maxdepth 3 -name action.yml -not -path '*/.git/*' | sort)
  if [ -n "$action_files" ] &&
    printf '%s\n' "$action_files" | xargs "$zizmor_bin" --no-progress --offline >"$WORK/actions.log" 2>&1; then
    pass "zizmor clean on all actions"
  else
    fail "zizmor reported findings on actions (see $WORK/actions.log)"
  fi
else
  printf '  skip zizmor on actions (not found)\n'
fi

printf '\n== deployed: yamllint exclude coverage ==\n'
# qlty.toml scopes yamllint out of the YAML install.sh deploys, because those
# files are read by actionlint/zizmor/Dependabot rather than held to a YAML style
# guide. Adding a new deployed .github/*.y(a)ml without adding it here makes qlty
# fail in every consuming repo, which is how .github/zizmor.yml and
# .github/actionlint.yaml shipped broken in 4.0beta13.
uncovered=""
for f in "$MAIN"/.github/*.yml "$MAIN"/.github/*.yaml; do
  [ -e "$f" ] || continue
  base=${f#"$MAIN"/}
  if ! grep -Fq "\"**/$base\"" "$MAIN/.qlty/qlty.toml"; then
    uncovered="$uncovered $base"
  fi
done
if [ -z "$uncovered" ]; then
  pass "every deployed .github YAML is in qlty.toml's yamllint exclude"
else
  fail "deployed .github YAML missing from qlty.toml yamllint exclude:$uncovered"
fi

printf '\n== self: dependabot covers every action ==\n'
# Dependabot's github-actions ecosystem scans <directory> literally for
# .github/workflows/ and action.yml. There is no root action.yml here, so every
# composite action directory must be named or its pinned third-party SHAs are
# never updated — which is what happened when the actions were first split out.
missing_dep=""
for f in $(find "$ROOT" -maxdepth 3 -name action.yml -not -path '*/.git/*' | sort); do
  d=$(dirname "${f#"$ROOT"}")
  grep -Fq "\"$d\"" "$ROOT/.github/dependabot.yml" || missing_dep="$missing_dep $d"
done
if [ -z "$missing_dep" ]; then
  pass "every action directory is listed in .Normal's dependabot.yml"
else
  fail "action directories missing from dependabot.yml:$missing_dep"
fi

printf '\n== actions: manifest contexts ==\n'
# GitHub evaluates ${{ }} when it LOADS an action manifest, where only inputs,
# github, runner, env, strategy, matrix-free contexts exist. A reference to
# matrix, secrets, needs, job or steps anywhere in action.yml -- including in an
# input description, which reads like prose but is not -- fails the whole
# manifest before a single step runs. No linter catches this: actionlint cannot
# parse action.yml and zizmor does not evaluate manifests, so only a live runner
# or this check will.
bad_ctx=""
for f in $(find "$ROOT" -maxdepth 3 -name action.yml -not -path '*/.git/*' | sort); do
  # Strip comment lines first: YAML drops them before the expression parser runs,
  # so a ${{ }} inside one is documentation, not a reference.
  if sed 's/[[:space:]]*#.*$//' "$f" |
    grep -Eq '\$\{\{[^}]*(matrix|secrets|needs|job|steps)\.'; then
    bad_ctx="$bad_ctx $f"
  fi
done
if [ -z "$bad_ctx" ]; then
  pass "no manifest-invalid contexts in any action.yml"
else
  fail "action.yml references a context unavailable at manifest load:$bad_ctx"
fi

printf '\n== self: .Normal own workflows ==\n'
if [ -n "$actionlint_bin" ]; then
  if "$actionlint_bin" -no-color -oneline "$ROOT"/.github/workflows/*.yml; then
    pass "actionlint clean on .Normal's own workflows"
  else
    fail "actionlint reported findings on .Normal's own workflows"
  fi
else
  printf '  skip actionlint on own workflows (not found)\n'
fi
if [ -n "$zizmor_bin" ]; then
  # Run from $ROOT so zizmor picks up .Normal's own .github/zizmor.yml.
  if (cd "$ROOT" && "$zizmor_bin" --no-progress --offline .github/workflows/ >"$WORK/self.log" 2>&1); then
    pass "zizmor clean on .Normal's own workflows"
  else
    fail "zizmor reported findings on .Normal's own workflows (see $WORK/self.log)"
  fi
else
  printf '  skip zizmor on own workflows (not found)\n'
fi

printf '\n%s checks, %s failures\n' "$CHECKS" "$FAILURES"
[ "$FAILURES" -eq 0 ]
