[![Build Status](https://travis-ci.org/eustasy/.normal.svg?branch=master)](https://travis-ci.org/eustasy/.normal)
[![Code Climate](https://codeclimate.com/github/eustasy/.normal/badges/gpa.svg)](https://codeclimate.com/github/eustasy/.normal)

### How to integrate

1.
```
git clone https://github.com/eustasy/.normal.git &&
cp normal-checks/install.sh install.sh &&
chmod 755 install.sh &&
cd .normal &&
git checkout b92da74ddf4b05b698e2d12ebd56e965d6749397 &&
cd ../ &&
./install.sh;
```
Enter password if required.
```
rm install.sh;
rm -Rf normal-checks;
```
2. Commit your changes.
```
git commit -am "Install eustasy/.Normal 2.0.0-beta";
git push
```
3. Travis CI Settings:
  - ON: Build only if .travis.yml is present
  - ON: Build branch updates
  - OFF: Limit concurrent jobs
  - ON: Build pull request updates
  - OFF: Auto cancel branch builds
  - OFF: Auto cancel pull request builds
  - CRON: Daily on master regardless.
4. Code Climate Settings
  - ON: Settings > Git Repository > Webhook on GitHub
  - ON: Settings > Git Repository > Integration with pull request status updates

### What it checks

| Test | Language | Travic CI | Code Climate |
|------|----------|-----------|--------------|
| Acorn | JavaScript      | Yes | N/a |
| JSON Validator | JSON   | Yes | N/a |
| Nginx Config | Conf     | No⁺ | No  |
| PHP Validator | PHP     | Yes | N/a |
| SQLint | SQL            | No⁺ | No  |
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
