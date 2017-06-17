#!/bin/sh
# Syntax check JavaScript with Acorn
# https://github.com/ternjs/acorn

set -e

echo "################################"
echo "Starting Javascript syntax check"
echo "################################"

npm install --silent -g acorn

acorn --silent "*.js"; echo $? 

echo "#################################"
echo "Javascript syntax check complete!"
echo "#################################"
