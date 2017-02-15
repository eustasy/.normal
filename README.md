[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=23271629)](https://www.bountysource.com/teams/eustasy/issues?tracker_ids=23271629)
[![Codacy Badge](https://api.codacy.com/project/badge/17a405e43e78405c900869b7f9359dfc)](https://www.codacy.com/app/lewisgoddard/normal-checks)
[![Code Climate](https://codeclimate.com/github/eustasy/normal-checks/badges/gpa.svg)](https://codeclimate.com/github/eustasy/normal-checks)
[![Build Status](https://travis-ci.org/eustasy/normal-checks.svg?branch=master)](https://travis-ci.org/eustasy/normal-checks)

### How to integrate

1. Copy [`travis-example.yml`](https://github.com/eustasy/normal-checks/blob/master/travis-example.yml) to your repo as `.travis.yml` and edit the email parameter and add any initialisers or tests you may have.
2. Copy [`.stylelintrc.json`](https://github.com/eustasy/normal-checks/blob/master/.stylelintrc.json) as well and use it to configure your CSS settings. This file should be valid JSON, and is based on the rules presented at [stylelint.io/user-guide/rules](https://stylelint.io/user-guide/rules/)
3. Optionally, copy [`.stylelintignore`](https://github.com/eustasy/normal-checks/blob/master/.stylelintignore) to show which files to ignore. This is usually best done if you have minified CSS in the repository. This file uses the same syntax as `.gitignore`
