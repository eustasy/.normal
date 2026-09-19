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
git commit -m "Install eustasy/.Normal 4.0beta15"
git push
```

### What it installs

| File | Purpose |
|------|---------|
| `.editorconfig` | Universal editor settings (indent, line length) |
| `.gitattributes` | LF line-ending normalization (**only if absent** — see below) |
| `.vscode/settings.json` | Format-on-save + recommended extensions |
| `.qlty/qlty.toml` | Qlty orchestration: plugins, smells, exclusions |
| `.qlty/configs/oxlint.json` | JS/TS linter (OXC) |
| `.qlty/configs/.stylelintrc.json` | CSS/SCSS linter |
| `.qlty/configs/.markdownlint.json` | Markdown linter |
| `.qlty/configs/.htmlvalidate.json` | HTML linter (void-style: selfclosing) |
| `.qlty/configs/ruff.toml` | Python lint + format |
| `.qlty/configs/.php-cs-fixer.dist.php` | PHP formatter |
| `.qlty/configs/.sqlfluff` | SQL lint + format (default dialect: mysql) |
| `.qlty/configs/.prettierrc.json` | Prettier config (JS/TS, JSON) |
| `.qlty/configs/.shellcheckrc` | Shell linter (source resolution; dialect from shebangs) |
| `.github/dependabot.yml` | Automated dependency updates (only ecosystems whose manifests are present) |
| `.github/zizmor.yml` | zizmor policy granting `eustasy/*` a ref-pin exemption |
| `.github/actionlint.yaml` | actionlint config; scopes the `if: false` deactivation pattern out of `if-cond` |
| `.github/workflows/security.yml` | Security scanning (every push) |
| `.github/workflows/{language}.yml` | Per-language lint + format CI |
| `.github/workflows/test-{language}.yml` | Test + coverage CI (activate by removing `if: false`) |
| `.github/workflows/type-{language}.yml` | Typecheck CI — TS (tsc), Python (mypy) (activate by removing `if: false`) |

### Default Branch

The CI workflows trigger on pushes and pull requests to your default branch. GitHub
Actions does not allow referencing the default branch dynamically in the `on:` trigger,
so the branch name has to be written into every `branches:` filter — `install.sh` does
this for you when it copies each workflow into place.

It reports what it picked:

```text
Default branch for workflow triggers: cf-pages
```

Detection order, most explicit first:

1. `NORMAL_DEFAULT_BRANCH`, if set.
2. `origin`'s recorded HEAD — the remote's default branch.
3. The branch currently checked out.
4. `main`.

Steps 2 and 3 cover a normal clone. Set the variable if the answer is wrong — most
often because the clone's `origin/HEAD` is stale, or because the repo has no remote
yet:

```bash
NORMAL_DEFAULT_BRANCH=trunk ./install.sh
```

`git remote set-head origin --auto` refreshes a stale `origin/HEAD` if you would
rather fix the cause.

### Customising a workflow

The deployed workflows are thin callers. The linting logic lives in composite
actions in this repository, referenced by the moving `v4` tag, so a fix reaches
every project as soon as the tag moves.

Anything a project needs to vary lives in the caller: the trigger and its path
filters, `runs-on`, the language matrix, service containers, and any extra steps.

Each language with a toolchain publishes three actions — `<language>/setup`,
`<language>/lint` and `<language>/test`. The flat `<language>` action runs setup
and lint in sequence, which is what the lint workflows call. Reach for the parts
when a job needs something in between. The `test-*` workflows already do, so
project-specific steps can sit between setup and the test run:

```yaml
      - uses: eustasy/.normal/php/setup@v4
        with:
          php-version: ${{ matrix.php-version }}
          coverage: pcov

      - name: Load database fixtures
        run: ./scripts/seed-test-db.sh

      - uses: eustasy/.normal/php/test@v4
        with:
          coverage-token: ${{ secrets.QLTY_COVERAGE_TOKEN }}
```

Because the actions are referenced by tag rather than by commit hash, every
project also receives `.github/zizmor.yml`, which grants the `eustasy`
namespace a `ref-pin` exemption. Without it zizmor fails each caller at high
severity. Everything else keeps zizmor's stricter hash-pinning default.

### Plugins

| Plugin | Language | Lint | Format |
|--------|----------|------|--------|
| oxc | JS / TS | Yes | — |
| knip | JS / TS | Yes | — |
| prettier | JS/TS, JSON | — | Yes |
| stylelint | CSS / SCSS | Yes | Yes |
| markdownlint | Markdown | Yes | — |
| html-validate | HTML | Yes | — |
| xmllint | XML | Yes | — |
| ruff | Python | Yes | Yes |
| phpstan | PHP | Yes | — |
| php-cs-fixer | PHP | — | Yes |
| sqlfluff | SQL | Yes | Yes |
| shellcheck | Shell | Yes | — |
| shfmt | Shell | — | Yes |
| yamllint | YAML | Yes | — |
| actionlint | YAML (GH Actions) | Yes | — |
| zizmor | YAML (GH Actions) | Yes | — |
| dotenv-linter | `.env` | Yes | — |
| gitleaks | All | Yes | — |
| trivy | All | Yes | — |
| osv-scanner | All | Yes | — |

### Line Endings

`.gitattributes` pins the tree to LF (`* text=auto eol=lf`), the companion to
`.editorconfig`'s `end_of_line = lf`. Together they stop the CRLF↔LF churn that
otherwise shows up as whole-file diffs on unchanged files when a repo is edited
from both Windows and WSL/Linux.

Unlike every other file `install.sh` deploys, **`.gitattributes` is installed only
when the project doesn't already have one.** It commonly carries project-specific
rules `.Normal` can't reconstruct — Git LFS `filter=lfs` lines,
`linguist-generated`/`linguist-vendored` overrides, custom merge drivers — and
overwriting those breaks LFS checkouts. If you already have one, `install.sh` says
so and leaves it alone; merge in the rules from
[`configs/.gitattributes`](https://github.com/eustasy/.normal/blob/main/configs/.gitattributes)
by hand.

If the repo already has CRLF committed, installing the file changes nothing on its
own. Normalize the tree once:

```bash
git add --renormalize .
git commit -m "Normalize line endings to LF"
```

### Shell Indentation

Shell scripts are formatted by **shfmt at 2 spaces**, pinned on the command line in
`.qlty/qlty.toml`:

```toml
[plugins.definitions.shfmt.drivers.format]
script = "shfmt -w -s -i 2 ${target}"
```

shfmt has no config file of its own. qlty's built-in driver passes no indentation
flag, so shfmt discovers `.editorconfig` at format time and falls back to its own
default — **tabs** — when it finds none. That is what made shell indentation flip
between tabs and spaces from machine to machine, and extensionless scripts never
matched an `.editorconfig` glob in the first place. Any formatting flag disables
shfmt's `.editorconfig` lookup, so `-i 2` both pins the width and removes the
discovery step.

`.editorconfig` carries the same value in `[*.{sh,bash,ksh,zsh,bats}]` for editors.
**Change both or neither** — they are not read by the same tool. To use 4 spaces
instead, set `-i 4` in `.qlty/qlty.toml` and `indent_size`/`tab_width` to `4` in
`.editorconfig`. Tabs are `-i 0` plus `indent_style = tab`.

VS Code deliberately has `"[shellscript]": { "editor.formatOnSave": false }` so an
ad-hoc shell-format extension on one machine can't reindent on save and fight CI.
Run `qlty fmt` to apply the real formatting.

### ShellCheck

`.qlty/configs/.shellcheckrc` sets `external-sources=true` and
`source-path=SCRIPTDIR` so `source`d files are followed and resolved against the
sourcing script rather than the caller's working directory. It deliberately does
**not** set `shell=`: that directive overrides every shebang in the repo and would
lint `#!/bin/sh` scripts as bash, hiding real portability bugs. Give shebang-less
fragments a per-file `# shellcheck shell=bash` directive instead.

ShellCheck never rewrites files — it has no say in indentation. See Shell
Indentation above.

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
git commit -m "Migrate to eustasy/.Normal 4.0beta15 (Qlty)";
git push
```

Then:

1. Connect the repo on [qlty.sh](https://qlty.sh) (replaces Code Climate)
2. Add `QLTY_COVERAGE_TOKEN` to repo secrets (Settings → Secrets → Actions)
3. Remove the `if: false` guard from whichever test/typecheck workflows apply to the repo

`install.sh` will automatically delete the old `.codeclimate.yml`, `.eslintrc.json`,
`.stylelintrc.json`, `.mdlrc`, and related files.

### Excluded Paths

Files are kept out of scope two ways:

1. **Git.** Gitignored paths are never linted. qlty respects `.gitignore`, and the
   JSON, JS, XML, and HTML workflows go further by feeding only `git ls-files`
   output (tracked files) to their tool — so build output, dependencies, and
   machine-managed files stay out without needing a pattern.
2. **qlty `exclude_patterns`.** Tracked files matching these are skipped by every
   qlty-driven plugin:

```
**/*.min.*   **/*.pack.*   **/*.custom.*   **/_libs/**
**/vendor/** **/node_modules/** **/dist/** **/build/**
**/out/**    **/coverage/**     **/__pycache__/** **/.pytest_cache/**
```

`xmllint` and `html-validate` run outside qlty, so they obey git tracking only —
the patterns above do **not** apply to XML or HTML. To drop an XML or HTML file
from CI, add it to `.gitignore`.
