# eustasy .Normal Checks

Normalized linting, formatting, and CI for eustasy applications. Covers HTML, Markdown,
JS/TS, CSS/SCSS, Python, PHP, XML, JSON, SQL, YAML, and Shell.

Powered by [Qlty](https://qlty.sh).

### How to integrate

```bash
git clone https://github.com/eustasy/.normal.git &&
cp .normal/install.sh install.sh &&
chmod 755 install.sh &&
./install.sh &&
rm install.sh &&
rm -Rf .normal
git add -A
git commit -m "Install eustasy/.Normal 4.0beta2"
git push
```

### What it installs

| File | Purpose |
|------|---------|
| `.editorconfig` | Universal editor settings (indent, line length) |
| `.vscode/settings.json` | Format-on-save + recommended extensions |
| `.qlty/qlty.toml` | Qlty orchestration: plugins, smells, exclusions |
| `.qlty/configs/oxlint.json` | JS/TS linter (OXC) |
| `.qlty/configs/.stylelintrc.json` | CSS/SCSS linter |
| `.qlty/configs/.markdownlint.jsonc` | Markdown linter |
| `.qlty/configs/ruff.toml` | Python lint + format |
| `.qlty/configs/.php-cs-fixer.php` | PHP formatter |
| `.qlty/configs/.sqlfluff` | SQL lint + format (default dialect: mysql) |
| `.qlty/configs/.prettierrc.json` | Prettier config (HTML, MD, JS/TS, CSS/SCSS, JSON, YAML, XML) |
| `.github/dependabot.yml` | Automated dependency updates |
| `.github/workflows/security.yml` | Security scanning (every push) |
| `.github/workflows/{language}.yml` | Per-language lint + format CI |
| `.github/workflows/test-{language}.yml` | Test + coverage CI (activate by removing `if: false`) |

### Plugins

| Plugin | Language | Lint | Format |
|--------|----------|------|--------|
| oxc | JS / TS | Yes | — |
| knip | JS / TS | Yes | — |
| prettier | HTML, MD, JS/TS, CSS/SCSS, JSON, YAML, XML | — | Yes |
| stylelint | CSS / SCSS | Yes | — |
| markdownlint | Markdown | Yes | — |
| ruff | Python | Yes | Yes |
| bandit | Python | Yes | — |
| php-codesniffer | PHP | Yes | — |
| phpstan | PHP | Yes | — |
| php-cs-fixer | PHP | — | Yes |
| sqlfluff | SQL | Yes | Yes |
| shellcheck | Shell | Yes | — |
| shfmt | Shell | — | Yes |
| yamllint | YAML | Yes | — |
| actionlint | YAML (GH Actions) | Yes | — |
| zizmor | YAML (GH Actions) | Yes | — |
| editorconfig-checker | All | Yes | — |
| dotenv-linter | `.env` | Yes | — |
| gitleaks | All | Yes | — |
| trivy | All | Yes | — |
| osv-scanner | All | Yes | — |

### SQL Dialect

The default SQL dialect is `mysql`. To override it in a project, add or edit
`.qlty/configs/.sqlfluff` after running `install.sh`:

```ini
[sqlfluff]
dialect = postgres
```

Any dialect supported by SQLFluff is valid (e.g. `postgres`, `sqlite`, `tsql`, `ansi`).

### Migrating from .Normal 3.x

```bash
git clone https://github.com/eustasy/.normal.git &&
cp .normal/install.sh install.sh &&
chmod 755 install.sh &&
./install.sh &&
rm install.sh &&
rm -Rf .normal;
git add -A;
git commit -m "Migrate to eustasy/.Normal 4.0 (Qlty, Prettier, Ruff)";
git push
```

Then:

1. Connect the repo on [qlty.sh](https://qlty.sh) (replaces Code Climate)
2. Add `QLTY_COVERAGE_TOKEN` to repo secrets (Settings → Secrets → Actions)
3. Remove the `if: false` guard from whichever test workflows apply to the repo

`install.sh` will automatically delete the old `.codeclimate.yml`, `.eslintrc.json`,
`.stylelintrc.json`, `.mdlrc`, and related files.

### Excluded Paths

```
**/*.min.*   **/*.pack.*   **/*.custom.*   **/_libs/**
**/vendor/** **/node_modules/** **/dist/** **/build/**
**/out/**    **/coverage/**     **/__pycache__/** **/.pytest_cache/**
```
