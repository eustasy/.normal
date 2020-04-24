#!/bin/sh

# Clean up older installs
rm .codacy.yml
rm check-config.sh
rm check-permissions.sh

# Set up current checks
cp normal-checks/.codeclimate.yml  .codeclimate.yml
cp normal-checks/.eslintrc.json    .eslintrc.json
cp normal-checks/.eslintignore     .eslintignore
cp normal-checks/.mdlrc            .mdlrc
cp normal-checks/.mdlrc.style.rb   .mdlrc.style.rb
cp normal-checks/.stylelintrc.json .stylelintrc.json
cp normal-checks/.stylelintignore  .stylelintignore
