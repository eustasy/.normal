#!/bin/sh
# Runs stylelint on all css files
# Requires nvm installed and project as git directory

set -e

echo "###################"
echo "Starting CSS checks"
echo "###################"

npm install --silent -g stylelint
npm install --silent -g stylelint-order
npm install --silent -g stylelint-csstree-validator
stylelint --config .stylelintrc.syntax.json "**/*.css"

if ! git --no-pager diff --quiet; then
    git --no-pager diff
    echo "#############################"
    echo "CSS checks detected an error."
    echo "#############################"
    exit 1;

else
    echo "####################"
    echo "CSS checks complete!"
    echo "####################"
    exit 0;
fi
