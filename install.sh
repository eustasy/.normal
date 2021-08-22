#!/bin/sh

# Clean up older installs
rm .codacy.yml
rm check-config.sh
rm check-permissions.sh

# Copy current dot files
cp .normal/.codeclimate.yml  .codeclimate.yml
cp .normal/.eslintrc.json    .eslintrc.json
cp .normal/.eslintignore     .eslintignore
cp .normal/.mdlrc            .mdlrc
cp .normal/.mdlrc.style.rb   .mdlrc.style.rb
cp .normal/.stylelintrc.json .stylelintrc.json
cp .normal/.stylelintignore  .stylelintignore
cp .normal/.travis.yml       .travis.yml
