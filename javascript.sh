
#!/bin/sh
# Lints all javascript files with standard
# Requires nvm installed

set -e

echo "###########################"
echo "Starting Javascript linting"
echo "###########################"

npm install standard

./node_modules/.bin/standard *.js

echo "############################"
echo "Javascript linting complete!"
echo "############################"
