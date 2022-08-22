#!/bin/sh

# Clean up older installs
rm .codacy.yml
rm check-config.sh
rm check-permissions.sh
rm .travis.yml

# Copy current dot files
cp .normal/.codeclimate.yml  .codeclimate.yml
cp .normal/.eslintrc.json    .eslintrc.json
cp .normal/.eslintignore     .eslintignore
cp .normal/.mdlrc            .mdlrc
cp .normal/.mdlrc.style.rb   .mdlrc.style.rb
cp .normal/.stylelintrc.json .stylelintrc.json
cp .normal/.stylelintignore  .stylelintignore
mkdir -p .github/workflows/
cp .normal/.github/workflows/normal.yml .github/workflows/normal.yml
