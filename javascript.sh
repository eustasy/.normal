#!/bin/sh
# Lints all javascript files with standard
# Requires nvm installed

set -e

echo "###########################"
echo "Starting Javascript linting"
echo "###########################"

sudo npm install --silent -g eslint-config-standard eslint-plugin-standard eslint-plugin-promise eslint

eslint \
    --ignore-pattern "*.min.js" \
    --ignore-pattern "*.pack.js" \
    "*.js"

echo "############################"
echo "Javascript linting complete!"
echo "############################"
