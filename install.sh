#!/bin/sh
set -e

# install.sh renders every file this version of .Normal ships into a staging
# directory, then merges each one into the project rather than copying over it.
# Projects change what .Normal gives them (activating a test-* workflow, adding
# a service container, widening a matrix, excluding a path from a linter), and
# an update that overwrote those changes forced every project to re-apply them
# by hand. Instead, each file gets a three-way merge, as `git merge` would do:
#
#   base    what the previous version of .Normal installed, rebuilt from that
#           version's tag in the .normal clone
#   ours    the project's file as it is now
#   theirs  what this version installs
#
# A file the project never changed simply updates. A changed file keeps its
# changes and still takes .Normal's. Where both touched the same lines, the file
# is left with conflict markers and install.sh exits non-zero.
#
# The previous version comes from the `# eustasy/.Normal <version>` header on the
# installed files. NORMAL_PREVIOUS_VERSION=<tag> overrides it, and
# NORMAL_OVERWRITE=1 skips merging entirely and overwrites, as install.sh used to.

# 1. Find the version the project has now. Checked before anything changes, so a
# missing tag can stop the install cleanly.
header_version() {
  sed -n '1s/^# eustasy\/\.Normal //p' "$1" 2>/dev/null
}
current=$(header_version .normal/configs/.github/workflows/security.yml)
previous=${NORMAL_PREVIOUS_VERSION:-}
if [ -z "$previous" ]; then
  for f in .github/workflows/security.yml .github/workflows/actions.yml .github/zizmor.yml .github/dependabot.yml; do
    [ -f "$f" ] || continue
    previous=$(header_version "$f")
    [ -n "$previous" ] && break
  done
fi

mode=merge
if [ "${NORMAL_OVERWRITE:-}" = 1 ]; then
  mode=overwrite
  echo "NORMAL_OVERWRITE=1: overwriting rather than merging."
elif [ -z "$previous" ]; then
  # Nothing carries a .Normal header, so this is a first install.
  mode=overwrite
fi

# The documented install clones .normal in full, so every release tag is
# present. A shallow clone, or a copy without .git, has none.
if [ "$mode" = merge ] && [ "$previous" != "$current" ] &&
  ! git -C .normal rev-parse -q --verify "refs/tags/${previous}^{commit}" >/dev/null 2>&1; then
  echo "This project has eustasy/.Normal $previous installed, but the .normal clone has no $previous tag," >&2
  echo "so there is nothing to merge its changes against. Nothing has been changed." >&2
  echo "  Clone .normal in full (git clone https://github.com/eustasy/.normal.git), or" >&2
  echo "  name the installed version with NORMAL_PREVIOUS_VERSION=<tag>, or" >&2
  echo "  overwrite every file as before with NORMAL_OVERWRITE=1." >&2
  exit 1
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# 2. Remove old files from previous .Normal versions (ignore missing)
rm -f \
  .codeclimate.yml \
  .eslintrc.json .eslintignore \
  .stylelintrc.json .stylelintignore \
  .mdlrc .mdlrc.style.rb \
  .codacy.yml .travis.yml check-config.sh check-permissions.sh \
  .prettierrc.json \
  .github/workflows/normal.yml
# .prettierrc.json moved into .qlty/configs/

# .gitattributes: line-ending normalization, the companion to .editorconfig's
# `end_of_line = lf`. Installed ONLY when absent, unlike everything else here.
# .gitattributes is commonly project-specific in ways .normal cannot reconstruct
# — Git LFS `filter=lfs` lines, `linguist-generated`/`linguist-vendored`
# overrides, custom merge drivers — and overwriting those breaks LFS checkouts.
# An existing file is left untouched and reported so a human can merge by hand.
if [ -e .gitattributes ]; then
  echo "Found existing .gitattributes; leaving it untouched (it may carry LFS or linguist rules)."
  echo "  To adopt .Normal's LF normalization, merge the rules from:"
  echo "    .normal/configs/.gitattributes"
  echo "    (also at https://github.com/eustasy/.normal/blob/main/configs/.gitattributes)"
else
  cp .normal/configs/.gitattributes .gitattributes
  echo "Installed .gitattributes (LF normalization)."
  echo "  If this repo has CRLF committed, normalize the tree once with:"
  echo "    git add --renormalize . && git commit -m 'Normalize line endings to LF'"
fi

# Default branch. Every workflow template ships with `branches: [main]` on its
# on.push / on.pull_request filters, because `on:` triggers cannot contain
# expressions — there is no `${{ github.event.repository.default_branch }}` to
# reach for. A repo whose default branch is anything else (e.g. cf-pages) would
# therefore install workflows that never trigger, so the filters are rewritten
# at install time.
#
# Detection order, most explicit first:
#   1. NORMAL_DEFAULT_BRANCH=... ./install.sh   (override; also the escape hatch
#      when the remote's HEAD is stale or the repo has no remote yet)
#   2. origin's HEAD, which is the remote's default branch. Only present if the
#      clone recorded it; refresh with `git remote set-head origin --auto`.
#   3. the currently checked-out branch, which is what a fresh clone sits on.
#   4. main.
default_branch=${NORMAL_DEFAULT_BRANCH:-}
if [ -z "$default_branch" ]; then
  default_branch=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||') || true
fi
if [ -z "$default_branch" ]; then
  default_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || true
fi
# `git rev-parse --abbrev-ref HEAD` prints HEAD (not a branch name) on a detached
# checkout, which is not a valid branch filter.
case $default_branch in
'' | HEAD) default_branch=main ;;
esac
echo "Default branch for workflow triggers: $default_branch"

# Copy one file from a configs/ tree into place, rewriting a workflow's branch
# filters when the default branch is not main. The base for a merge is rendered
# the same way, so the rewrite never shows up as a difference.
# $1 = configs root, $2 = path relative to it, $3 = destination
render_config() {
  mkdir -p "$(dirname "$3")"
  case $2 in
  .github/workflows/*.yml)
    if [ "$default_branch" != main ]; then
      sed "s|^\([[:space:]]*branches: \)\[main\]\$|\1[${default_branch}]|" "$1/$2" >"$3"
      return 0
    fi
    ;;
  esac
  cp "$1/$2" "$3"
}

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

# Stage a workflow only if matching files exist, reporting the count either way
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
    render_config .normal/configs ".github/workflows/${wf}.yml" "$stage/.github/workflows/${wf}.yml"
  else
    echo "Found 0 $wf file(s); skipping $wf workflow."
  fi
}

# Dependabot: only declare ecosystems whose package manifests are actually present,
# so a repo isn't nagged about package managers it doesn't use. github-actions is
# always included because install.sh always installs the security and actions workflows,
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

# 3. Stage everything this version installs.
stage=$tmp/theirs
mkdir -p "$stage/.qlty/configs" "$stage/.github/workflows" "$stage/.vscode"

# EditorConfig + VS Code settings
render_config .normal/configs .editorconfig "$stage/.editorconfig"
render_config .normal/configs .vscode/settings.json "$stage/.vscode/settings.json"

# Qlty config + all linter/formatter configs
render_config .normal/configs .qlty/qlty.toml "$stage/.qlty/qlty.toml"
cp -R ".normal/configs/.qlty/configs/." "$stage/.qlty/configs/"

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
# eustasy/.Normal 5.0
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
} >"$stage/.github/dependabot.yml"

# zizmor policy. Required by every caller workflow, which references .Normal's
# actions by moving tag rather than by hash; see configs/.github/zizmor.yml.
render_config .normal/configs .github/zizmor.yml "$stage/.github/zizmor.yml"
echo "Installed zizmor policy (eustasy/* ref-pin)."

# actionlint config. Scopes the `if: false` deactivation pattern out of if-cond,
# which would otherwise fail every repo that leaves a test-* workflow inactive.
render_config .normal/configs .github/actionlint.yaml "$stage/.github/actionlint.yaml"
echo "Installed actionlint config."

# Security workflow always runs regardless of file types present.
render_config .normal/configs .github/workflows/security.yml "$stage/.github/workflows/security.yml"
echo "Installed security workflow (always)."

# Always, for the same reason as security: install.sh writes workflows into every
# repository, so actionlint and zizmor always have something to lint. Gating this
# on a file count can never legitimately return zero.
render_config .normal/configs .github/workflows/actions.yml "$stage/.github/workflows/actions.yml"
echo "Installed actions workflow (always)."

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
copy_workflow type-js    "*.ts" "*.mts" "*.cts"
copy_workflow type-python "*.py"
copy_workflow xml        "*.xml"
copy_workflow yaml       "*.yml" "*.yaml"

# 4. Rebuild what the previous version installed, as the base for each merge.
base=$tmp/base
if [ "$mode" = merge ]; then
  if [ "$previous" = "$current" ]; then
    previous_tree=.normal
  else
    previous_tree=$tmp/previous
    mkdir -p "$previous_tree"
    git -C .normal archive "$previous" | tar -x -C "$previous_tree"
  fi
  echo "Merging eustasy/.Normal $previous -> $current."

  # Every file .Normal ships as a template installs at the same path it has
  # under configs/, so the base is that template, rendered as above.
  (cd "$previous_tree/configs" && find . -type f ! -name .gitattributes) | sed 's|^\./||' |
    while IFS= read -r f; do
      render_config "$previous_tree/configs" "$f" "$base/$f"
    done

  # dependabot.yml is generated rather than copied, so rebuild it by running the
  # previous installer in a sandbox holding only the root manifests it detects.
  sandbox=$tmp/sandbox
  mkdir -p "$sandbox"
  for m in .gitmodules bun.lock bun.lockb package.json package-lock.json npm-shrinkwrap.json \
    yarn.lock pnpm-lock.yaml composer.json requirements.txt pyproject.toml Pipfile setup.py setup.cfg; do
    if [ -e "$m" ]; then : >"$sandbox/$m"; fi
  done
  cp -R "$previous_tree" "$sandbox/.normal"
  if (cd "$sandbox" && NORMAL_DEFAULT_BRANCH=$default_branch NORMAL_OVERWRITE=1 sh .normal/install.sh) >/dev/null 2>&1 &&
    [ -f "$sandbox/.github/dependabot.yml" ]; then
    mkdir -p "$base/.github"
    cp "$sandbox/.github/dependabot.yml" "$base/.github/dependabot.yml"
  fi
fi

# 5. Merge (or overwrite) each file into the project.
updated=""
merged=""
conflicts=""
added=""
removed=""
kept=""
note() {
  eval "$1=\"\$$1
    \$2\""
}

# A file the previous version would have installed but the project doesn't have
# was either never installed (its file type is new to the project) or deleted on
# purpose, like a test-* workflow the project doesn't want. Only git knows which.
was_deleted() {
  [ -n "$(git log -1 --format=%h --diff-filter=D -- "$1" 2>/dev/null)" ]
}

merge_one() {
  f=$1
  theirs=$stage/$f
  basef=$base/$f
  if [ -f "$theirs" ]; then
    if [ ! -e "$f" ]; then
      if [ "$mode" = merge ] && [ -f "$basef" ] && was_deleted "$f"; then
        note kept "$f (deleted in this project; not re-added)"
        return 0
      fi
      mkdir -p "$(dirname "$f")"
      cp "$theirs" "$f"
      note added "$f"
    elif cmp -s "$f" "$theirs"; then
      return 0
    elif [ "$mode" = overwrite ] || { [ -f "$basef" ] && cmp -s "$f" "$basef"; }; then
      cp "$theirs" "$f"
      note updated "$f"
    elif [ ! -f "$basef" ]; then
      note kept "$f (not installed by $previous, so left as it is; .Normal's copy is .normal/configs/$f)"
    else
      rc=0
      git merge-file -p -L "$f (this project)" -L "$f ($previous)" -L "$f ($current)" \
        "$f" "$basef" "$theirs" >"$tmp/merged" || rc=$?
      if [ "$rc" -gt 127 ]; then
        echo "git merge-file failed on $f" >&2
        exit 1
      fi
      # The project's changes already cover everything this version changed.
      if [ "$rc" -eq 0 ] && cmp -s "$tmp/merged" "$f"; then
        return 0
      fi
      cp "$tmp/merged" "$f"
      if [ "$rc" -eq 0 ]; then
        note merged "$f"
      else
        note conflicts "$f"
      fi
    fi
  elif [ -e "$f" ]; then
    # This version doesn't install the file: its file type is gone from the
    # project, or .Normal stopped shipping it.
    if [ "$mode" = overwrite ]; then
      case $f in
      .github/workflows/*.yml)
        rm -f "$f"
        note removed "$f"
        ;;
      esac
    elif [ -f "$basef" ] && cmp -s "$f" "$basef"; then
      rm -f "$f"
      note removed "$f"
    elif [ -f "$basef" ]; then
      note kept "$f (changed in this project, though $current no longer installs it)"
    fi
  fi
}

# Every path either version installs, plus, when overwriting, every workflow
# .Normal manages, so ones whose file types are gone are dropped as before.
{
  (cd "$stage" && find . -type f) | sed 's|^\./||'
  if [ -d "$base" ]; then (cd "$base" && find . -type f) | sed 's|^\./||'; fi
  if [ "$mode" = overwrite ]; then
    for wf in security actions css env html js json md php python sh sql test-js test-php test-python type-js type-python xml yaml; do
      echo ".github/workflows/${wf}.yml"
    done
  fi
} | sort -u >"$tmp/paths"
while IFS= read -r f; do
  merge_one "$f"
done <"$tmp/paths"

report() {
  if [ -n "$2" ]; then
    printf '%s%s\n' "$1" "$2"
  fi
}
report "Added:" "$added"
report "Updated:" "$updated"
report "Merged with this project's changes:" "$merged"
report "Removed:" "$removed"
report "Left alone:" "$kept"
if [ -n "$conflicts" ]; then
  report "CONFLICTS, resolve the <<<<<<< markers before committing:" "$conflicts"
  exit 1
fi
