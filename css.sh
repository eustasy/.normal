#!/bin/sh
# Runs csscomb on all css files
# Requires nvm installed and project as git directory

set -e

echo "####################"
echo "Starting CSS linting"
echo "####################"

npm install csscomb

./node_modules/.bin/csscomb *.css

if ! git diff --quiet styles/; then
    git diff styles/

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
