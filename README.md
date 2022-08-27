[![Normal](https://github.com/eustasy/.normal/actions/workflows/normal.yml/badge.svg)](https://github.com/eustasy/.normal/actions/workflows/normal.yml)
[![Code Climate](https://codeclimate.com/github/eustasy/.normal/badges/gpa.svg)](https://codeclimate.com/github/eustasy/.normal)

### How to integrate

1.
```bash
git clone https://github.com/eustasy/.normal.git &&
cp .normal/install.sh install.sh &&
chmod 755 install.sh &&
./install.sh &&
rm install.sh &&
rm -Rf .normal;
git add .github/workflows/normal.yml;
git commit -am "Install eustasy/.Normal 3.0";
git push;
```

2. Code Climate Settings
  - ON: Settings > Git Repository > Webhook on GitHub
  - ON: Settings > Git Repository > Integration with pull request status updates

### What it checks

| Test | Language | GitHub Actions | Code Climate |
|------|----------|----------------|--------------|
| Acorn | JavaScript      | Yes | N/a |
| JSON Validator | JSON   | Yes | N/a |
| Nginx Config | Conf     | No⁺ | No  |
| PHP Validator | PHP     | Yes | N/a |
| SQLint | SQL            | Yes | No  |
| XML Validator | XML     | Yes | N/a |
| Duplication | All       | No  | Yes |
| FixMe | All             | No  | Yes |
| Coverage | PHP          | No  | Yes |
| CSSLint | CSS           | No  | No^ |
| ESLint | JavaScript     | No  | Yes |
| MarkdownLint | Markdown | No  | Yes |
| PHPCodeSniffer | PHP    | No  | Yes |
| PHPMD | PHP             | No  | Yes |
| Rubocop | Ruby          | No  | No^ |
| Shellcheck | Bash       | No  | Yes |
| Stylelint | CSS         | No  | Yes |

^ Not configured for this runtime.  
⁺ Waiting to be implemented.

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
- *.sql
- *.xml

### Excluded Paths

Most test exclude the following paths:

- _libs/*
- *.min.css
- *.custom.css
- *.min.js
- *.pack.js
- *.custom.js
