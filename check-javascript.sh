#!/bin/sh
# Syntax check JavaScript with Acorn
# https://github.com/ternjs/acorn
# inspired by https://stackoverflow.com/a/24385950/1239965

set -e

echo "################################"
echo "Starting Javascript syntax check"
echo "################################"

npm install --silent -g acorn

find `pwd` -name '*.js' | xargs acorn --silent {}; echo $? 

echo "#################################"
echo "Javascript syntax check complete!"
echo "#################################"
