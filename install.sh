#!/bin/sh
set -e

# 1. Remove old files from previous .Normal versions (ignore missing)
rm -f \
  .codeclimate.yml \
  .eslintrc.json .eslintignore \
  .stylelintrc.json .stylelintignore \
  .mdlrc .mdlrc.style.rb \
  .codacy.yml .travis.yml check-config.sh check-permissions.sh \
  .prettierrc.json \
  .github/workflows/normal.yml
# .prettierrc.json moved into .qlty/configs/

# 2. Create required directories
mkdir -p .qlty/configs .github/workflows .vscode

# 3. EditorConfig + VS Code settings
cp .normal/configs/.editorconfig         .editorconfig
cp .normal/configs/.vscode/settings.json .vscode/settings.json

# 4. Qlty config + all linter/formatter configs
cp .normal/configs/.qlty/qlty.toml   .qlty/qlty.toml
cp -R ".normal/configs/.qlty/configs/." ".qlty/configs/"

# 5. GitHub workflows

# Count non-excluded files matching a single name pattern. Both the pruned dirs
# and the skipped file names mirror qlty.toml's excludes — tool dirs (.vscode,
# .claude, .qlty), deps/build output, composer.json and min/pack/custom bundles —
# so files .normal never lints aren't counted (a repo whose only JSON is
# composer.json reports 0 .json files). ./install.sh is skipped too: the documented
# "clone and run" copies this installer to the repo root, and it must not count
# itself as a shell script and pull in sh.yml. phpunit.xml is skipped as well: it's
# a PHPUnit test-runner config, not the kind of XML content xml.yml exists to lint,
# so a PHP repo whose only .xml file is phpunit.xml gets no xml workflow. (The more
# commonly committed phpunit.xml.dist already fails the *.xml glob, so it needs no
# skip here.)
count_files() {
  find . -type d \( -name .git -o -name .github -o -name .normal -o -name .qlty -o -name .vscode -o -name .claude -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name out -o -name coverage -o -name __pycache__ -o -name .pytest_cache -o -name .venv -o -name _libs \) -prune -o -type f -name "$1" ! -path './install.sh' ! -name composer.json ! -name phpunit.xml ! -name '*.min.*' ! -name '*.pack.*' ! -name '*.custom.*' -print 2>/dev/null | wc -l
}

# Install a workflow only if matching files exist, reporting the count either way
# so it's obvious which workflows were installed and why.
copy_workflow() {
  wf=$1
  shift
  count=0
  for pat in "$@"; do
    count=$((count + $(count_files "$pat")))
  done
  if [ "$count" -gt 0 ]; then
    echo "Found $count $wf file(s); installing $wf workflow."
    cp ".normal/configs/.github/workflows/${wf}.yml" ".github/workflows/${wf}.yml"
  else
    echo "Found 0 $wf file(s); skipping $wf workflow."
  fi
}

# Remove .normal-managed workflows before re-checking, so updating .normal drops
# any whose file types are no longer present (or are now excluded). Workflows the
# project added itself are left untouched.
for wf in security css env html js json md php python sh sql test-js test-php test-python xml yaml; do
  rm -f ".github/workflows/${wf}.yml"
done

# Dependabot: only declare ecosystems whose package manifests are actually present,
# so a repo isn't nagged about package managers it doesn't use. github-actions is
# always included because install.sh always installs at least the security workflow,
# so there are always pinned action versions to keep updated. Detection is root-only
# to match the directory: "/" each block declares; manifests in subdirectories are
# out of scope (as they were with the old static config).
has_manifest() {
  for f in "$@"; do
    [ -e "./$f" ] && return 0
  done
  return 1
}

# Semver-versioned ecosystems (github-actions/bun/npm/composer/pip) share one
# template: group their non-breaking bumps into a single "<name>-patching" PR.
# $1 = ecosystem (also the group-name prefix); $2 = "allow" to add
# `allow: dependency-type: all`, which we want for package managers with transitive
# dependencies (bun/npm/composer/pip) but not for github-actions, where every
# dependency is already direct.
ecosystem_block() {
  cat <<EOF
  - package-ecosystem: "$1"
    directory: "/"
    schedule:
      interval: "monthly"
EOF
  if [ "$2" = allow ]; then
    cat <<'EOF'
    allow:
      - dependency-type: "all"
EOF
  fi
  cat <<EOF
    groups:
      $1-patching:
        update-types:
          - "minor"
          - "patch"
EOF
}

# gitsubmodule (the ecosystem value is singular) tracks commits, not semver, so the
# minor/patch grouping above would never match; group every submodule bump into one
# PR instead.
gitsubmodule_block() {
  cat <<'EOF'
  - package-ecosystem: "gitsubmodule"
    directory: "/"
    schedule:
      interval: "monthly"
    groups:
      gitsubmodule-all:
        patterns:
          - "*"
EOF
}

# Map detected manifests to dependabot's package-ecosystem values. These mirror the
# languages .normal already lints/tests (JS/TS, PHP, Python), plus github-actions
# (always) and gitsubmodule (a vendoring mechanism, not a file type, so it has no
# linter — keyed purely off .gitmodules). For JS, dependabot splits bun into its own
# ecosystem while npm covers npm/yarn/pnpm; a bun repo still carries a package.json,
# so detect bun first and don't also enable npm for it.
echo "Installing dependabot config (github-actions always included)."
gitsubmodule=0; bun=0; npm=0; composer=0; pip=0
if has_manifest .gitmodules; then gitsubmodule=1; echo "  Found .gitmodules; adding gitsubmodule ecosystem."; else echo "  No .gitmodules; skipping gitsubmodule ecosystem."; fi
if has_manifest bun.lock bun.lockb; then
  bun=1; echo "  Found a bun lockfile; adding bun ecosystem."
elif has_manifest package.json package-lock.json npm-shrinkwrap.json yarn.lock pnpm-lock.yaml; then
  npm=1; echo "  Found an npm/yarn/pnpm manifest; adding npm ecosystem."
else
  echo "  No JS manifest; skipping bun/npm ecosystems."
fi
if has_manifest composer.json; then composer=1; echo "  Found composer.json; adding composer ecosystem."; else echo "  No composer manifest; skipping composer ecosystem."; fi
if has_manifest requirements.txt pyproject.toml Pipfile setup.py setup.cfg; then pip=1; echo "  Found a Python manifest; adding pip ecosystem."; else echo "  No Python manifest; skipping pip ecosystem."; fi

{
  cat <<'EOF'
# eustasy/.Normal 4.0beta10
# To get started with Dependabot version updates, you'll need to specify which
# package ecosystems to update and where the package manifests are located.
# Please see the documentation for all configuration options:
# https://docs.github.com/github/administering-a-repository/configuration-options-for-dependency-updates

version: 2
updates:
EOF
  ecosystem_block github-actions
  if [ "$gitsubmodule" = 1 ]; then gitsubmodule_block;            fi
  if [ "$bun" = 1 ];          then ecosystem_block bun allow;      fi
  if [ "$npm" = 1 ];          then ecosystem_block npm allow;      fi
  if [ "$composer" = 1 ];     then ecosystem_block composer allow; fi
  if [ "$pip" = 1 ];          then ecosystem_block pip allow;      fi
} > .github/dependabot.yml

# Security workflow always runs regardless of file types present.
cp .normal/configs/.github/workflows/security.yml .github/workflows/security.yml
echo "Installed security workflow (always)."

copy_workflow css        "*.css" "*.scss"
copy_workflow env        ".env*"
copy_workflow html       "*.html" "*.htm"
copy_workflow js         "*.js" "*.ts" "*.mjs" "*.cjs" "*.mts" "*.cts"
copy_workflow json       "*.json"
copy_workflow md         "*.md"
copy_workflow php        "*.php"
copy_workflow python     "*.py"
copy_workflow sh         "*.sh"
copy_workflow sql        "*.sql"
copy_workflow test-js    "*.js" "*.ts" "*.mjs" "*.cjs" "*.mts" "*.cts"
copy_workflow test-php   "*.php"
copy_workflow test-python "*.py"
copy_workflow xml        "*.xml"
copy_workflow yaml       "*.yml" "*.yaml"
