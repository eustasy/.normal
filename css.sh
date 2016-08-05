#!/bin/sh
# Runs csscomb on all css files
# Requires nvm installed and project as git directory

set -e

echo "####################"
echo "Starting CSS linting"
echo "####################"

sudo npm install -g csscomb

csscomb .

if ! git diff --quiet; then
    git diff

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
