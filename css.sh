#!/bin/sh
# Runs csscomb on all css files
# Requires nvm installed and project as git directory

set -e

echo "####################"
echo "Starting CSS linting"
echo "####################"

sudo npm install -g postcss postcss-cli postcss-reporter stylelint autoprefixer

postcss --config .postcss.json

if ! git diff --quiet; then
    git --no-pager diff

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
