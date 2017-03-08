#!/bin/sh
# Lints all javascript files with standard
# Requires nvm installed

set -e

echo "###########################"
echo "Starting Javascript linting"
echo "###########################"

npm install --silent -g eslint-config-standard eslint-plugin-standard eslint

eslint "*.js"

echo "############################"
echo "Javascript linting complete!"
echo "############################"
