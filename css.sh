#!/bin/sh
# Runs stylelint on all css files
# Requires nvm installed and project as git directory

set -e

echo "####################"
echo "Starting CSS linting"
echo "####################"

sudo npm install --silent -g stylelint stylelint-order
stylelint --config .stylelintrc.json "**/*.css"

if ! git --no-pager diff --quiet; then
    git --no-pager diff

    echo "##############################"
    echo "CSS linting detected an error."
    echo "##############################"

    exit 1;
else
    echo "#####################"
    echo "CSS linting complete!"
    echo "#####################"

    exit 0;
fi
