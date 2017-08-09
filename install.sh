#!/bin/sh
# Install

set -e

find . -type d -exec sudo chmod 755 {} \;
find . -type f -exec sudo chmod 644 {} \;
find . -type f -name "*.sh" -exec sudo chmod 755 {} \;

cp normal-checks/.codacy.yml       .codacy.yml
cp normal-checks/.codeclimate.yml  .codeclimate.yml
cp normal-checks/.eslintrc.json    .eslintrc.json
cp normal-checks/.eslintignore     .eslintignore
cp normal-checks/.mdlrc            .mdlrc
cp normal-checks/.mdlrc.style.rb   .mdlrc.style.rb
cp normal-checks/.stylelintrc.json .stylelintrc.json
cp normal-checks/.stylelintignore  .stylelintignore
