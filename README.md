[![Build Status](https://travis-ci.org/eustasy/normal-checks.svg?branch=master)](https://travis-ci.org/eustasy/normal-checks)
[![Codacy Badge](https://api.codacy.com/project/badge/17a405e43e78405c900869b7f9359dfc)](https://www.codacy.com/app/lewisgoddard/normal-checks)
[![Code Climate](https://codeclimate.com/github/eustasy/normal-checks/badges/gpa.svg)](https://codeclimate.com/github/eustasy/normal-checks)
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=23271629)](https://www.bountysource.com/teams/eustasy/issues?tracker_ids=23271629)

### How to integrate

1. 
```
git clone https://github.com/eustasy/normal-checks.git &&
cp normal-checks/.travis.yml .travis.yml &&
cd normal-checks &&
git checkout d5f1a5d9e3fbac391b905f2bdfcdcdbfe465eabf &&
cd ../ &&
./normal-checks/check-config.sh;
./normal-checks/check-permissions.sh;
rm -Rf normal-checks
```
2. Edit the `.travis.yml` email parameter and add any initialisers or tests you may have.
3. Travis CI Settings:
  - ON: Build only if .travis.yml is present
  - ON: Build branch updates
  - OFF: Limit concurrent jobs 
  - ON: Build pull request updates
  - ON: Auto cancel branch builds
  - ON: Auto cancel pull request builds
  - CRON: Daily on master regardless.
4. Codacy Settings:
  - ON: Settings > Integrations > Github Pull Requests > All options
  - ON: Settings > Integrations > GitHub Post Commit Hook
  - ON: Code Patterns > JacksonLinter (both settings)
  - ON: Code Patterns > Stylelint
  - OFF: Code Patterns > All others.
5. Code Climate Settings
  - ON: Settings > Git Repository > Webhook on GitHub
  - ON: Settings > Git Repository > Integration with pull request status updates

### What it checks

| Test | Language | Travic CI | Codacy | Code Climate |
|------|----------|-----------|--------|--------------|
| Config | Conf           | Yes | N/a | N/a |
| Coverage | PHP          | No  | Yes | Yes |
| CSSLint | CSS           | No  | No  | No  |
| Duplication | All       | No  | Yes | Yes |
| ESLint | JavaScript     | Yes | No  | Yes |
| FixMe | All             | No  | **N/a** | Yes |
| JacksonLinter | JSON    | No  | Yes | **N/a** |
| JSON Validator* | JSON  | Yes | N/a | N/a |
| MarkdownLint | Markdown | No  | **N/a** | Yes |
| Metrics | All           | No  | Yes | No  |
| Permissions | All       | Yes | N/a | N/a |
| PHPCodeSniffer | PHP    | No  | **N/a** | Yes |
| PHPMD | PHP             | No  | No^ | Yes |
| PHP Validator* | PHP    | Yes | N/a | N/a |
| Rubocop | Ruby          | No  | No  | No  |
| Shellcheck | Bash       | No  | No  | Yes |
| Stylelint | CSS         | Yes | Yes | **N/a** |
| XML Validator* | XML    | Yes | N/a | N/a |

*Not true checkers, just syntax.  
^Not configured for this runtime.  
**Bold** indicates something required for Codacy or Code Climate to totally replace the other. Codacy have issue navigation down much better, Code Climate won't let you filter down to a generator/rule level.

### Checked Files

Tests cover the following extensions:

- *.conf
- *.css
- *.js
- *.json
- *.md
- *.phar
- *.php
- *.sh
- *.xml

### Excluded Paths

Most test exclude the following paths:

- _libs/*
- *.min.css
- *.custom.css
- *.min.js
- *.pack.js
- *.custom.js

