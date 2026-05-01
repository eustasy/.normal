#!/bin/sh
set -e

# 1. Remove old files from previous .Normal versions (ignore missing)
rm -f .codeclimate.yml
rm -f .eslintrc.json .eslintignore
rm -f .stylelintrc.json .stylelintignore
rm -f .mdlrc .mdlrc.style.rb
rm -f .codacy.yml .travis.yml check-config.sh check-permissions.sh
rm -f .prettierrc.json  # moved into .qlty/configs/
rm -f .github/workflows/normal.yml

# 2. Create required directories
mkdir -p .qlty/configs .github/workflows .vscode

# 3. EditorConfig + VS Code settings
cp .normal/configs/.editorconfig         .editorconfig
cp .normal/configs/.vscode/settings.json .vscode/settings.json

# 4. Qlty config + all linter/formatter configs
cp .normal/configs/.qlty/qlty.toml   .qlty/qlty.toml
cp .normal/configs/.qlty/configs/*   .qlty/configs/

# 5. GitHub workflows
cp .normal/configs/.github/dependabot.yml                .github/dependabot.yml
cp .normal/configs/.github/workflows/php.yml             .github/workflows/php.yml
cp .normal/configs/.github/workflows/python.yml          .github/workflows/python.yml
cp .normal/configs/.github/workflows/js.yml              .github/workflows/js.yml
cp .normal/configs/.github/workflows/css.yml             .github/workflows/css.yml
cp .normal/configs/.github/workflows/sh.yml              .github/workflows/sh.yml
cp .normal/configs/.github/workflows/sql.yml             .github/workflows/sql.yml
cp .normal/configs/.github/workflows/md.yml              .github/workflows/md.yml
cp .normal/configs/.github/workflows/html.yml            .github/workflows/html.yml
cp .normal/configs/.github/workflows/xml.yml             .github/workflows/xml.yml
cp .normal/configs/.github/workflows/json.yml            .github/workflows/json.yml
cp .normal/configs/.github/workflows/yaml.yml            .github/workflows/yaml.yml
cp .normal/configs/.github/workflows/env.yml             .github/workflows/env.yml
cp .normal/configs/.github/workflows/security.yml        .github/workflows/security.yml
cp .normal/configs/.github/workflows/test-php.yml        .github/workflows/test-php.yml
cp .normal/configs/.github/workflows/test-python.yml     .github/workflows/test-python.yml
cp .normal/configs/.github/workflows/test-js.yml         .github/workflows/test-js.yml
