[![Build Status](https://travis-ci.org/eustasy/normal-checks.svg?branch=master)](https://travis-ci.org/eustasy/normal-checks)
[![Codacy Badge](https://api.codacy.com/project/badge/17a405e43e78405c900869b7f9359dfc)](https://www.codacy.com/app/lewisgoddard/normal-checks)
[![Code Climate](https://codeclimate.com/github/eustasy/normal-checks/badges/gpa.svg)](https://codeclimate.com/github/eustasy/normal-checks)
[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=23271629)](https://www.bountysource.com/teams/eustasy/issues?tracker_ids=23271629)

### How to integrate

1. Copy [`.travis.yml`](https://github.com/eustasy/normal-checks/blob/master/.travis.yml) to your repo as `.travis.yml` and edit the email parameter and add any initialisers or tests you may have.
2. 
```
git clone https://github.com/eustasy/normal-checks.git
./normal-checks/check-config.sh
rm -R normal-checks
```

### What it checks

| Test | Language | Travic CI | Codacy | Code Climate |
|------|----------|-----------|--------|--------------|
| Config | Conf           | Yes | N/a | N/a |
| Coverage | PHP          | No  | Yes | Yes |
| CSSLint | CSS           | No  | No  | No  |
| Duplication | All       | No  | Yes | Yes |
| ESLint | JavaScript     | Yes | No  | Yes |
| FixMe | All             | No  | No  | Yes |
| JacksonLinter | JSON    | No  | Yes | N/a |
| JSON Validator* | JSON  | Yes | N/a | N/a |
| MarkdownLint | Markdown | No  | No  | Yes |
| Metrics | All           | No  | Yes | No  |
| Permissions | All       | Yes | N/a | N/a |
| PHPCodeSniffer | PHP    | No  | N/a | Yes |
| PHPMD | PHP             | No  | No  | Yes |
| PHP Validator* | PHP    | Yes | N/a | N/a |
| Rubocop | Ruby          | No  | No  | No  |
| Shellcheck | Bash       | No  | No  | Yes |
| Stylelint | CSS         | Yes | Yes | N/a |
| XML Validator* | XML    | Yes | N/a | N/a |

*Not true checkers, just syntax.

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
- *.min.js

