#!/bin/sh
# Runs stylelint on all css files
# Requires nvm installed and project as git directory

set -e

echo "####################"
echo "Starting CSS linting"
echo "####################"

sudo npm install -g stylelint

stylelint --config .stylelintrc.json "*.css"

if ! git diff --no-pager --quiet; then
    git diff --no-pager

    echo "##############################################################"
    echo "CSS linting detected an error. Please use csscomb and resubmit"
    echo "##############################################################"

    exit 1;
else
    echo "#####################"
    echo "CSS linting complete!"
    echo "#####################"

    exit 0;
fi
