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

# Check if any non-excluded files matching the given name patterns exist in the
# repo. Both the pruned dirs and the skipped file names mirror qlty.toml's
# excludes — tool dirs (.vscode, .claude, .qlty), deps/build output, composer.json
# and min/pack/custom bundles — so files .normal never lints don't trigger a
# workflow install (e.g. a repo whose only JSON is composer.json gets no json.yml).
has_files() {
  for pat in "$@"; do
    match=$(find . -type d \( -name .git -o -name .github -o -name .normal -o -name .qlty -o -name .vscode -o -name .claude -o -name node_modules -o -name vendor -o -name dist -o -name build -o -name out -o -name coverage -o -name __pycache__ -o -name .pytest_cache -o -name _libs \) -prune -o -type f -name "$pat" ! -name composer.json ! -name '*.min.*' ! -name '*.pack.*' ! -name '*.custom.*' -print -quit 2>/dev/null)
    [ -n "$match" ] && return 0
  done
  return 1
}

# Copy a workflow only if matching files exist in the repo.
copy_workflow() {
  wf=$1
  shift
  if has_files "$@"; then
    cp ".normal/configs/.github/workflows/${wf}.yml" ".github/workflows/${wf}.yml"
  fi
}

# Remove .normal-managed workflows before re-checking, so updating .normal drops
# any whose file types are no longer present (or are now excluded). Workflows the
# project added itself are left untouched.
for wf in security css env html js json md php python sh sql test-js test-php test-python xml yaml; do
  rm -f ".github/workflows/${wf}.yml"
done

cp .normal/configs/.github/dependabot.yml .github/dependabot.yml

# Security workflow always runs regardless of file types present.
cp .normal/configs/.github/workflows/security.yml .github/workflows/security.yml

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
