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

# Check if any files matching the given name patterns exist in the repo,
# excluding tool directories (.git, .github, .normal, .qlty).
has_files() {
  for pat in "$@"; do
    match=$(find . \( -path './.git' -o -path './.github' -o -path './.normal' -o -path './.qlty' \) -prune -o -name "$pat" -print -quit 2>/dev/null)
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
